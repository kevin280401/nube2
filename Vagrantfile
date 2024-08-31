Vagrant.configure("2") do |config|
  # Configuración del servidor Consul
  config.vm.define "consul-master" do |consul|
    consul.vm.box = "ubuntu/jammy64"
    consul.vm.network "private_network", ip: "192.168.50.10"
    consul.vm.hostname = "consul-master"
    consul.vm.provision "shell", inline: <<-SHELL
      # Instala Consul
      wget https://releases.hashicorp.com/consul/1.14.3/consul_1.14.3_linux_amd64.zip
      unzip consul_1.14.3_linux_amd64.zip
      sudo mv consul /usr/local/bin/
      sudo mkdir /etc/consul.d
      sudo mkdir /var/lib/consul
      sudo useradd --system --home /etc/consul.d --shell /bin/false consul
      sudo chown -R consul:consul /etc/consul.d /var/lib/consul

      # Configura Consul para correr como servidor
      sudo tee /etc/systemd/system/consul.service > /dev/null <<EOF
      [Unit]
      Description=Consul Agent
      Documentation=https://www.consul.io/
      Requires=network-online.target
      After=network-online.target

      [Service]
      User=consul
      Group=consul
      ExecStart=/usr/local/bin/consul agent -server -bootstrap-expect=1 -data-dir=/var/lib/consul -config-dir=/etc/consul.d -bind=192.168.50.10
      ExecReload=/bin/kill -HUP $MAINPID
      KillMode=process
      Restart=on-failure
      LimitNOFILE=65536

      [Install]
      WantedBy=multi-user.target
      EOF

      sudo systemctl enable consul
      sudo systemctl start consul
    SHELL
  end

  # Configuración de los agentes Consul
  (1..4).each do |i|
    config.vm.define "web#{i}" do |web|
      web.vm.box = "ubuntu/jammy64"
      web.vm.network "private_network", ip: "192.168.50.1#{i + 1}"
      web.vm.hostname = "web#{i}"
      web.vm.provision "shell", inline: <<-SHELL
        # Instala Consul
        wget https://releases.hashicorp.com/consul/1.14.3/consul_1.14.3_linux_amd64.zip
        unzip consul_1.14.3_linux_amd64.zip
        sudo mv consul /usr/local/bin/
        sudo mkdir /etc/consul.d
        sudo mkdir /var/lib/consul
        sudo useradd --system --home /etc/consul.d --shell /bin/false consul
        sudo chown -R consul:consul /etc/consul.d /var/lib/consul

        # Configura Consul para correr como agente
        sudo tee /etc/systemd/system/consul.service > /dev/null <<EOF
        [Unit]
        Description=Consul Agent
        Documentation=https://www.consul.io/
        Requires=network-online.target
        After=network-online.target

        [Service]
        User=consul
        Group=consul
        ExecStart=/usr/local/bin/consul agent -data-dir=/var/lib/consul -config-dir=/etc/consul.d -bind=192.168.50.1#{i + 1} -retry-join=192.168.50.10
        ExecReload=/bin/kill -HUP $MAINPID
        KillMode=process
        Restart=on-failure
        LimitNOFILE=65536

        [Install]
        WantedBy=multi-user.target
        EOF

        sudo systemctl enable consul
        sudo systemctl start consul

        # Instala NodeJS
        curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt-get install -y nodejs

        # Crear un simple servidor web en NodeJS
        echo "const http = require('http');
        const hostname = '0.0.0.0';
        const port = 3000;
        http.createServer((req, res) => {
          res.writeHead(200, {'Content-Type': 'text/plain'});
          res.end('Hello from web#{i}!');
        }).listen(port, hostname);" > ~/server.js

        # Ejecutar el servidor
        nohup node ~/server.js &
      SHELL
    end
  end

  # Configuración del balanceador de carga HAProxy
  config.vm.define "haproxy" do |haproxy|
    haproxy.vm.box = "ubuntu/jammy64"
    haproxy.vm.network "private_network", ip: "192.168.50.20"
    haproxy.vm.hostname = "haproxy"
    haproxy.vm.provision "shell", inline: <<-SHELL
      # Instala HAProxy
      sudo apt-get update
      sudo apt-get install -y haproxy

      # Configura HAProxy para balanceo de carga
      sudo tee /etc/haproxy/haproxy.cfg > /dev/null <<EOF
      global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private
        ssl-default-bind-ciphers PROFILE=SYSTEM
        ssl-default-server-ciphers PROFILE=SYSTEM

      defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000

      frontend http_front
        bind *:80
        stats uri /haproxy?stats
        default_backend servers

      backend servers
        balance roundrobin
        server web1 192.168.50.12:3000 check
        server web2 192.168.50.13:3000 check
        server web3 192.168.50.14:3000 check
        server web4 192.168.50.15:3000 check
        errorfile 503 /etc/haproxy/errors/503.http
      EOF

      # Crea la página de error personalizada
      sudo tee /etc/haproxy/errors/503.http > /dev/null <<EOF
      HTTP/1.0 503 Service Unavailable
      Cache-Control: no-cache
      Connection: close
      Content-Type: text/html

      <html>
      <body>
      <h1>Service Unavailable</h1>
      <p>Sorry, the server is currently unavailable. Please try again later.</p>
      </body>
      </html>
      EOF

      # Reinicia HAProxy para aplicar la configuración
      sudo systemctl restart haproxy
    SHELL
  end
end
