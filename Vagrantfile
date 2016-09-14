Vagrant.configure(2) do |config|
    config.vm.box = "bento/ubuntu-16.04"

    config.vm.provider :virtualbox do |vb|
        vb.name = "pgbackrest-demo-ubuntu-16.04"
    end

    # Provision the VM
    config.vm.provision "shell", inline: <<-SHELL
        # Install db
        echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update
        apt-get install -y postgresql-9.5
        pg_dropcluster --stop 9.5 main

        # Install Perl modules required for demo.pl
        apt-get install -y libterm-readkey-perl

        # Install pgBackRest
        apt-get install -y pgbackrest
        chown vagrant /etc/pgbackrest.conf
        chown vagrant /var/log/pgbackrest

        # Make default run directory writable to vagrant
        mkdir /var/run/postgresql
        chmod 777 /var/run/postgresql

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
