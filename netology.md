# Диплом

Все действия будут производиться на домашней машине.

Для начала подготовим системные переменные для Yandex Cloud и Gitlab:

```bash
$ export YC_STORAGE_ACCESS_KEY="XXXXXXXXXXXXXX-XXXXXXXXXX"
$ export YC_STORAGE_SECRET_KEY="XXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$ export YC_SERVICE_ACCOUNT_KEY_FILE="/home/vagrant/.yckey.json"
$ export GITLAB_PRIVATE_TOKEN="xxxxx-XXXXXXXXXXXXXXXXXXXX"
$ export GITLAB_AGENT_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
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
![https://github.com/Jekker600/diploma/blob/main/img/1.jpg](https://github.com/Jekker600/diploma/blob/main/img/1.jpg)

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
![https://github.com/Jekker600/diploma/blob/main/img/2.jpg](https://github.com/Jekker600/diploma/blob/main/img/2.jpg)

Напишем манифесты для [terraform](https://github.com/Jekker600/diploma/blob/main/terraform)
Подключимся к `app.terraform.io` через анонимный прокси, настроим там наш репозиторий с терраформом и проверим как всё само работает: