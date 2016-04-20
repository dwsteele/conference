Vagrant.configure(2) do |config|
    config.vm.box = "boxcutter/ubuntu1404"

    config.vm.provider :virtualbox do |vb|
        vb.name = "pgbackrest-demo-ubuntu-14.04"
    end

    # Provision the VM
    config.vm.provision "shell", inline: <<-SHELL
        # Install db
        echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update
        apt-get install -y postgresql-9.5
        pg_dropcluster --stop 9.5 main

        # Install required Perl modules
        apt-get -y --force-yes install libdbd-pg-perl libdbi-perl libnet-daemon-perl libplrpc-perl libterm-readkey-perl

        # Install pgBackRest
        wget -q -O - https://github.com/pgbackrest/pgbackrest/archive/release/1.00.tar.gz | tar zx -C ~
        sudo cp -r ~/pgbackrest-release-1.00/lib/pgBackRest /usr/lib/perl5
        sudo find /usr/lib/perl5/pgBackRest -type f -exec chmod 644 {} +
        sudo find /usr/lib/perl5/pgBackRest -type d -exec chmod 755 {} +
        sudo cp ~/pgbackrest-release-1.00/bin/pgbackrest /usr/bin/pgbackrest
        sudo chmod 755 /usr/bin/pgbackrest
        sudo mkdir -m 770 /var/log/pgbackrest
        sudo chown vagrant:postgres /var/log/pgbackrest

        # Create pgpackrest.conf
        touch /etc/pgbackrest.conf
        chown vagrant:vagrant /etc/pgbackrest.conf

        # Make default run directory writable to vagrant
        mkdir /var/run/postgresql
        chmod 777 /var/run/postgresql

        # Install texlive for building slides
        apt-get install -y ghostscript

        mkdir /root/texlive
        wget -q -O - http://mirror.hmc.edu/ctan/systems/texlive/tlnet/install-tl-unx.tar.gz \
            | tar zxv -C /root//texlive --strip-components=1
        echo "collection-basic 1" >> /root/texlive/texlive.profile
        echo "collection-latex 1" >> /root/texlive/texlive.profile
        /root/texlive/install-tl -profile=/root/texlive/texlive.profile

        echo 'PATH=/usr/local/texlive/2015/bin/x86_64-linux:$PATH' >> /etc/profile
        echo 'export PATH' >> /etc/profile

        /usr/local/texlive/2015/bin/x86_64-linux/tlmgr install beamer ms pbox epstopdf
    SHELL

  # Don't share the default vagrant folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Mount demo path for testing
  config.vm.synced_folder "demo", "/demo"

  # Mount slides path for building slides
  config.vm.synced_folder "slides", "/slides"
end
