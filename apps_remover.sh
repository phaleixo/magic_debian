#!/usr/bin/env bash

# Solicitar a senha de forma gráfica usando zenity com personalização
password=$(zenity --password --title="Autenticação necessária" --text="Digite sua senha:")

# Verificar se a operação foi cancelada
if [[ $? -ne 0 ]]; then
    # Abrir a página de erro no Flask
    xdg-open "http://localhost:5000/error"
    exit 1
fi


apps_remove=(
    fcitx*
    mozc*
    xiterm+thai*
    mlterm*
    xterm*
    hdate*
    kasumi*
    gnome-games*
    im*
    goldendict*
    hdate*
    uim*
    thunderbird*
    gnome-music
)

# Desinstalar e limpar
for app_name_remove in "${apps_remove[@]}"; do
    echo "$password" | sudo -S apt remove --purge "$app_name_remove" -y
done

# Limpar pacotes não utilizados e cache
echo "$password" | sudo -S apt autoremove -y
echo "$password" | sudo -S apt autoclean -y

# Limpar a variável da senha
unset password
