Vagrant.configure(2) do |config|
    config.vm.box = "bento/ubuntu-16.04"

    config.vm.provider :virtualbox do |vb|
        vb.name = "hp-pgbackrest-ubuntu-16.04"
    end

    # Provision the VM
    config.vm.provision "shell", inline: <<-SHELL
        # Update apt repository
        sudo apt-get update

        # Install texlive and beamer for building slides
        apt-get install -y texlive texlive-latex-extra
    SHELL

  # Don't share the default vagrant folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Mount slides path for building slides
  config.vm.synced_folder ".", "/talk"

  # Mount Crunchy slide template
  config.vm.synced_folder "../template", "/template"
end
