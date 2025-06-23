## .qcow2 Image File Sharing

You need to upload the `.qcow2` extension image files that you want to open to this folder.

Our Ansible machine will access this folder, read the file name and create a script with this file name, and provide **automatic opening** in our Windows virtual machine.

> Folder synchronization is provided in our `Vagrantfile` file with the following command:

```ruby
config.vm.synced_folder File.expand_path("../images", __dir__), "/home/vagrant/shared_images", type: "rsync"

```

This way, our `../images` folder appears in the `/home/vagrant/shared_images` folder on our Ansible machine.
