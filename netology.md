# Диплом

Все действия будут производиться на домашней машине.

Для начала подготовим системные переменные для Yandex Cloud:

```bash
$ export YC_STORAGE_ACCESS_KEY="XXXXXXXXXXXXXX-XXXXXXXXXX"
$ export YC_STORAGE_SECRET_KEY="XXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$ export YC_SERVICE_ACCOUNT_KEY_FILE="/home/vagrant/.yckey.json"
```
>1.Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
```bash
$ yc iam service-account get terraform-agent
id: aje4o75no91tn71jgisd
folder_id: b1gurqobqm3qcn2l5eem
created_at: "2022-06-21T16:16:31Z"
name: terraform-agent
```
Терраформ аутентифицируется этим сервисным аккаунтом с помощью IAM-ключа, который в json-формате содержится в файле, указанным в переменной `YC_SERVICE_ACCOUNT_KEY_FILE`.
```bash
$ yc resource-manager folder list-access-bindings netology
+--------------------------+----------------+----------------------+
|         ROLE ID          |  SUBJECT TYPE  |      SUBJECT ID      |
+--------------------------+----------------+----------------------+
| resource-manager.admin   | serviceAccount | aje4o75no91tn71jgisd |
| container-registry.admin | serviceAccount | aje4o75no91tn71jgisd |
| editor                   | serviceAccount | aje4o75no91tn71jgisd |
+--------------------------+----------------+----------------------+
```
>2.Подготовьте backend для Terraform (Рекомендуемый вариант: Terraform Cloud)

Создадим руками через web-интерфейс YC s3 backet и проинициализируем terraform backend:
![](https://github.com/Jekker600/diplom/blob/main/1.jpg)

```bash
$ terraform init -backend-config "access_key=$YC_STORAGE_ACCESS_KEY" -backend-config "secret_key=$YC_STORAGE_SECRET_KEY"

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of yandex-cloud/yandex from the dependency lock file
- Using previously-installed yandex-cloud/yandex v0.75.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
![](https://github.com/Jekker600/diplom/blob/main/2.jpg)

Подключимся к `app.terraform.io` через анонимный прокси, настроим там наш репозиторий с терраформом и проверим как всё само работает:

>снимки экрана из Terraform Cloud.

![](https://github.com/Jekker600/diplom/blob/main/diploma-tfc.png)

>Настройте workspaces

В TFC созданы два воркспейса, `yc-stage` и `yc-prod`. Внутри конфигурации Терраформа они преобразуются в просто stage/prod, и в таком виде передаются и далее в плейбуки. Терраформ берёт нужный воркспейс из переменной `TF_WORKSPACE`.

В зависимости от выбранного воркспейса меняются ресурсы, выделенные кластеру, а так же выбирается соответствующее окружение для первоначального развёртывания тестового приложения.

# Создание Kubernetes кластера

Для развёртывания кластера мы используем Ansible / Kubespray, все дополнения также устанавливаем с помощью плейбуков.
Ансибль с помощью проекта [terraform-inventory](https://github.com/adammck/terraform-inventory) использует Терраформ-стейты в качестве динамического инвентори, при этом имена `compute_instances`-ресурсов превращаются в группы хостов, а все outputs доступны как ansible vars. Кроме того, для настройки Kubespray мы подключаем [дополнительное инвентори](https://github.com/Jekker600/diplom/tree/main/custom-inventory).

SSH-ключ для доступа к хостам передаётся в переменных `ssh_key_pub` и `ssh_key_priv`.

Сразу вместе с кластером мы устанавливаем и [NGINX Ingress Controller](https://github.com/Jekker600/diplom/blob/main/custom-inventory/group_vars/k8s_cluster/ingress_controller.yml), который будет использоваться в режиме `hostNetwork`. Кажется, это самый простой путь получить для ингрессов 80/443 порты, без использования сервисов типа `loadBalancer`, которые зависят от облачного провайдера, или своего собственного балансировщика MetalLB, которому для анонса потребуются дополнительные IP-адреса.
Кроме того, мы делаем DNS-запись для этого ингресс-контроллера с указанием IP всех воркер-нод, и на эту запись CNAME-ми вешаем записи для всех остальных ингрессов.

После успешного развёртывания кластера мы [импортируем](https://github.com/Jekker600/diplom/blob/main/playbooks/import-cluster-config.yaml) его конфиг (далее он предоставляется требующим его программам с помощью переменной `KUBECONFIG`), [сохраняем](https://github.com/Jekker600/diplom/blob/main/playbooks/save-infra-info.yaml) некоторую информацию о кластере и инфраструктуре (которая потом используется при деплое тестового приложения), и [устанавливаем](https://github.com/Jekker600/diplom/blob/main/playbooks/k8s-dashboard.yaml) Dashboard, токен доступа к которой сохраняем в артифакты сборки.

Wildcard-cертификат для наших веб-ресурсов мы предоставляем в переменных `tls_crt` и `tls_priv`.

# Подготовка cистемы мониторинга

В соответствии с рекомендациями, используем пакет kube-prometheus. Мы храним только [файл кастомных настроек](https://github.com/Jekker600/diplom/blob/main/kube-prometheus/custom-setup.jsonnet), всё остальное [плейбук](https://github.com/Jekker600/diplom/blob/main/playbooks/kube-prometheus.yaml) делает во время деплоя сам - инициализирует сборочную среду, собирает и применяет манифесты, подсовывает секрет с сертификатом.

Пароль для Графаны передаётся в переменной `grafana_pass`.

# CI/CD
Мы будем использовать CI/CD от GitLab. Инфраструктура - дело серьёзно-опасное, да к тому же и не быстрое, поэтому тут никакой автоматики, и для запуска пайплайна будем пользоваться исключительно кнопкой `Run pipeline` в веб-интерфейсе гитлаба, а выбор выполняемых в пайплайне задач мы будем делать с помощью указания специально обученных переменных.

Стадий получилось многовато, но распараллелить задачи особенно не получится, они все зависят одна от другой. Последняя задача триггерит запуск пайплайна в репозитории тестового приложения, для его первоначального деплоя в свежесозданный кластер.

Для сборки образа инфраструктурного контейнера нужно запустить пайплайн с `BUILD_IMG=1`.

Для полного деплоя всей инфраструктуры нужно запустить пайплайн с `RUN_TESTS=1` и `RUN_DEPLOY=1`.
