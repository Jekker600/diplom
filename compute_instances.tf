# VMs resources
# master nodes
resource "yandex_compute_instance" "kube_control_plane" {
  count    = local.k8s_cluster_resources[local.ws].masters.count
  name     = "kb-master-${count.index}"
  hostname = "kb-master-${count.index}"
  # distribute VM instances across available zones/subnets
  zone = local.networks[count.index - floor(count.index / length(local.networks)) * length(local.networks)].zone_name

  resources {
    cores  = local.k8s_cluster_resources[local.ws].masters.cpu
    memory = local.k8s_cluster_resources[local.ws].masters.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.alma8.id
      type     = local.k8s_cluster_resources[local.ws].masters.disk_type
      size     = local.k8s_cluster_resources[local.ws].masters.disk
    }
  }

  network_interface {
    # distribute VM instances across available zones/subnets
    subnet_id = yandex_vpc_subnet.public[count.index - floor(count.index / length(local.networks)) * length(local.networks)].id
    nat       = true
  }

  scheduling_policy {
    preemptible = local.k8s_cluster_resources[local.ws].masters.preemptible
  }

  metadata = {
    ssh-keys = "AAAAB3NzaC1yc2EAAAADAQABAAABgQCypB08FX77oLEARFamdKtLKP2g3VPImzsWX43juZSKwcWv4kxctZxvLMvlZ0JM/SFETeN3uvxwnscR3Mf+FkneK5UYAfAn/95cHYse8UJlkjpE8kpe8jIT6rx3zpf5X7yhoxh79wUpePhvoulmG9Ao2Y5z9zeK4gtRrtIOOWsMjn4JbCR5h0AVenHAR7tID9KhahCMUTKN7oYKE1Brm5i30SuGHB2tzJN0e+FpayzE77sOn5VyttgKGyT9YDbFYvoixZ1MXhF908+KzR643HFb69r10rNehxCWJ6mYbDb+O8o1CgijH+YSi0JJ6/gLIuXHJ7fEU32pODm5+8k/EZ5RLFCnOv4H6gjuG8Fd4h4XyHGYX95egG7R2/RzEp4Q+ip2zj3XquzBZ4E0aFaRvSJclTtf994bWR4SY1otyh1OncGIrcScqIgVaZ9AT/6Cka7diLSl5LVRrCRBdk/WvchPyI3taO6eX2g4m+uQbFeyXjFlZAui5reuxUSESU31pm0= vagrant@minicub"
  }
}


# worker nodes
resource "yandex_compute_instance" "kube_node" {
  count    = local.k8s_cluster_resources[local.ws].workers.count
  name     = "kb-worker-${count.index}"
  hostname = "kb-worker-${count.index}"
  # distribute VM instances across available zones/subnets
  zone = local.networks[count.index - floor(count.index / length(local.networks)) * length(local.networks)].zone_name


  resources {
    cores  = local.k8s_cluster_resources[local.ws].workers.cpu
    memory = local.k8s_cluster_resources[local.ws].workers.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.alma8.id
      type     = local.k8s_cluster_resources[local.ws].workers.disk_type
      size     = local.k8s_cluster_resources[local.ws].workers.disk
    }
  }

  network_interface {
    # distribute VM instances across available zones/subnets
    subnet_id = yandex_vpc_subnet.public[count.index - floor(count.index / length(local.networks)) * length(local.networks)].id
    nat       = true
  }

  scheduling_policy {
    preemptible = local.k8s_cluster_resources[local.ws].workers.preemptible
  }

  metadata = {
    ssh-keys = "AAAAB3NzaC1yc2EAAAADAQABAAABgQCypB08FX77oLEARFamdKtLKP2g3VPImzsWX43juZSKwcWv4kxctZxvLMvlZ0JM/SFETeN3uvxwnscR3Mf+FkneK5UYAfAn/95cHYse8UJlkjpE8kpe8jIT6rx3zpf5X7yhoxh79wUpePhvoulmG9Ao2Y5z9zeK4gtRrtIOOWsMjn4JbCR5h0AVenHAR7tID9KhahCMUTKN7oYKE1Brm5i30SuGHB2tzJN0e+FpayzE77sOn5VyttgKGyT9YDbFYvoixZ1MXhF908+KzR643HFb69r10rNehxCWJ6mYbDb+O8o1CgijH+YSi0JJ6/gLIuXHJ7fEU32pODm5+8k/EZ5RLFCnOv4H6gjuG8Fd4h4XyHGYX95egG7R2/RzEp4Q+ip2zj3XquzBZ4E0aFaRvSJclTtf994bWR4SY1otyh1OncGIrcScqIgVaZ9AT/6Cka7diLSl5LVRrCRBdk/WvchPyI3taO6eX2g4m+uQbFeyXjFlZAui5reuxUSESU31pm0= vagrant@minicub"
  }
}

