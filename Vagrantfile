Vagrant.configure(2) do |config|
    config.vm.box = "bento/ubuntu-16.04"

    config.vm.provider :virtualbox do |vb|
        vb.name = "pg-review-demo-ubuntu-16.04"
    end

    # Provision the VM
    config.vm.provision "shell", inline: <<-SHELL
        # Suppress "dpkg-reconfigure: unable to re-open stdin: No file or directory" warning
        export DEBIAN_FRONTEND=noninteractive

        # Update apt
        apt-get update

        # Install Texlive
        apt-get install -y texlive texlive-latex-extra
    SHELL

  # Don't share the default vagrant folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Mount slides path for building slides
  config.vm.synced_folder ".", "/talk"

  # Mount Crunchy slide template
  config.vm.synced_folder "../template", "/template"
end
