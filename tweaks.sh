#!/usr/bin/env bash

# Solicitar a senha de forma gráfica usando zenity com personalização
password=$(zenity --password --title="Autenticação necessária" --text="Digite sua senha:")

# Verificar se a operação foi cancelada
if [[ $? -ne 0 ]]; then
    # Abrir a página de erro no Flask
    xdg-open "http://localhost:5000/error"
    exit 1
fi


# Ativar o repositório contrib e non-free
echo "$password" | sudo -S apt-add-repository contrib -y
echo "$password" | sudo -S apt-add-repository non-free -y
echo "$password" | sudo -S apt update && echo "$password" | sudo -S apt full-upgrade -y

# Instalar suporte a flatpak e adicionar o repositório flathub
echo "$password" | sudo -S apt install gnome-software-plugin-flatpak -y 
echo "$password" | sudo -S flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Remover o Firefox ESR
echo "$password" | sudo -S apt remove --purge firefox-esr -y

# Criar um diretório para armazenar as chaves de repositório APT, se ainda não existir
echo "$password" | sudo -S install -d -m 0755 /etc/apt/keyrings

# Importar a chave de assinatura do repositório APT da Mozilla
echo "$password" | sudo -S wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

# Adicionar o repositório APT da Mozilla às suas fontes
echo 'deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main' | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null

# Configurar o APT para priorizar pacotes do repositório da Mozilla
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla 

# Atualizar a lista de pacotes e instalar o pacote Firefox .deb
echo "$password" | sudo -S apt-get update -y && echo "$password" | sudo -S apt-get install firefox -y && echo "$password" | sudo -S apt-get install firefox-l10n-pt-br -y

# Instalar codecs, fontes e ajustes
apps=(  
    exfat-fuse 
	ffmpeg 
	ffmpegthumbnailer 
	firmware-amd-graphics 
	firmware-linux-nonfree 
	font-manager 
	fonts-croscore 
	fonts-noto 
	fonts-noto-extra 
	fonts-ubuntu 
	gir1.2-gtop-2.0 
	gnome-browser-connector 
	gnome-firmware 
	gnome-tweaks 
	gstreamer1.0-plugins-ugly 
	gstreamer1.0-vaapi 
	gufw 
	libavcodec-extra 
	ldap-utils 
	libasound2-plugins 
	micro 
	vdpauinfo
	python3-pip
	python3
	gnome-boxes
	p7zip-rar
	ntp
	network-manager-config-connectivity-debian
	ttf-mscorefonts-installer
)

for app_name in "${apps[@]}"; do
  if ! dpkg -l | grep -q "$app_name"; then
    echo "$password" | sudo -S apt install "$app_name" -y
  else
    echo "[installed] - $app_name"
  fi
done

# Adicionar arquitetura i386
echo "$password" | sudo -S dpkg --add-architecture i386

# Criar diretório de fontes
echo "$password" | sudo -S mkdir -p ~/.fonts

# Verificar e instalar wget e unzip se não estiverem presentes
if ! command -v wget &> /dev/null; then
    echo "$password" | sudo -S apt update && echo "$password" | sudo -S apt install wget -y
fi

if ! command -v unzip &> /dev/null; then
    echo "$password" | sudo -S apt update && echo "$password" | sudo -S apt install unzip -y
fi

# Baixar e instalar fontes Fira
echo "$password" | wget -O fonts.zip "https://github.com/mozilla/Fira/archive/refs/tags/4.202.zip"
echo "$password" | wget -O firacode.zip "https://github.com/tonsky/FiraCode/releases/download/1.204/FiraCode_1.204.zip"

# Descompactar e instalar fontes
echo "$password" | unzip fonts.zip -d ~/.fonts
echo "$password" | unzip firacode.zip -d ~/.fonts

# Atualizar cache de fontes
echo "$password" | fc-cache -v -f

# Configurar as fontes no GNOME
echo "$password" | gsettings set org.gnome.desktop.interface document-font-name 'Fira Sans Regular 11'
echo "$password" | gsettings set org.gnome.desktop.interface font-name 'Fira Sans Regular 11'
echo "$password" | gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace Regular 12'
echo "$password" | gsettings set org.gnome.nautilus.desktop font 'Fira Sans Regular 11'
echo "$password" | gsettings set org.gnome.desktop.wm.preferences titlebar-font "Fira Sans SemiBold 12"

# Remover arquivos temporários
echo "$password" | rm -rf fonts.zip
echo "$password" | rm -rf firacode.zip

# Verificar o driver de vídeo
video_driver_info=$(lspci -k | grep amdgpu)
video_card_info=$(lspci | grep VGA)

if [[ "$video_driver_info" == *"Kernel driver in use: amdgpu"* ]]; then
    # Amdgpu driver is already active
    echo "Video card: '$video_card_info'"
    echo "----------------------------------------------------------------"
    echo "The amdgpu driver is already active. No action required."
elif [[ "$video_driver_info" == *"Kernel driver in use: radeon"* ]]; then
    # Switch from radeon to amdgpu
    echo "Video card: '$video_card_info'"
    echo "----------------------------------------------------------------"
    echo "Switching driver from radeon to amdgpu..."
    sed_command='s/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 radeon.cik_support=0 amdgpu.cik_support=1 radeon.si_support=0 amdgpu.si_support=1"/'

    if echo "$password" | sudo -S sed -i "$sed_command" /etc/default/grub && echo "$password" | sudo -S update-grub; then
        echo "Driver configuration updated successfully. Restart the system to apply the changes."
    else
        echo "Error updating GRUB or changing the driver. Please restart the system manually after fixing the issue."
    fi
else
    # No AMDGPU or Radeon driver detected
    echo "Video card: '$video_card_info'"
    echo "----------------------------------------------------------------"
    echo "Unable to detect the AMDGPU or Radeon video driver on the system."
fi

# Limpar a variável da senha
unset password
