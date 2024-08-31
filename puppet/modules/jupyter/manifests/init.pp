class jupyter {
    # Instala Python y pip
    package { ['python3', 'python3-pip']:
        ensure => installed,
    }

    # Instala Jupyter usando pip
    exec { 'install_jupyter':
        command => '/usr/bin/pip3 install jupyter',
        path    => '/usr/bin/',
        require => Package['python3-pip'],
    }

    # Crear directorio para Jupyter Notebooks
    file { '/home/vagrant/notebooks':
        ensure => 'directory',
        owner  => 'vagrant',
        group  => 'vagrant',
        mode   => '0755',
        require => Exec['install_jupyter'],
    }

    # Crear un servicio systemd para Jupyter Notebook
    file { '/etc/systemd/system/jupyter.service':
        ensure  => 'file',
        content => "
