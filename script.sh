#!/bin/bash

# Configuración del resolv.conf
echo "Configurando el resolv.conf con cat"
cat <<TEST> /etc/resolv.conf
nameserver 8.8.8.8
TEST

# Instalación de vsftpd
echo "Instalando un servidor vsftpd"
sudo apt-get update
sudo apt-get install vsftpd -y

# Modificación de vsftpd.conf
echo "Modificando vsftpd.conf con sed"
sudo sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf

# Configuración de IP forwarding
echo "Configurando IP forwarding con echo"
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf

# Instalación de Python y pip
echo "Instalando Python y pip"
sudo apt-get install python3-pip -y

# Instalación de Jupyter Notebook
echo "Instalando Jupyter Notebook"
pip3 install jupyter

# Confirmar que Jupyter está instalado
if ! command -v /home/vagrant/.local/bin/jupyter-notebook &> /dev/null
then
    echo "Jupyter Notebook no se pudo instalar correctamente."
    exit 1
fi

# Configurar Jupyter Notebook como servicio
echo "Configurando Jupyter Notebook como servicio"
cat <<EOF | sudo tee /etc/systemd/system/jupyter.service
[Unit]
Description=Jupyter Notebook

[Service]
Type=simple
PIDFile=/run/jupyter.pid
ExecStart=/home/vagrant/.local/bin/jupyter-notebook --config=/home/vagrant/.jupyter/jupyter_notebook_config.py
User=vagrant
Group=vagrant
WorkingDirectory=/home/vagrant
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Recargar el daemon y habilitar el servicio de Jupyter
sudo systemctl daemon-reload
sudo systemctl enable jupyter.service
sudo systemctl start jupyter.service

echo "Jupyter Notebook ha sido instalado y configurado como un servicio."

