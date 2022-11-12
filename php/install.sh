#!/usr/bin/env bash
# Based on https://github.com/devcontainers/features/blob/main/src/php/install.sh

VERSION=${VERSION:-"8.1"}
EXTENSIONS=${EXTENSIONS:-"pgsql,sqlite3,gd,curl,imap,mysql,mbstring,zip,bcmath,soap,intl,readline,ldap,msgpack,igbinary,redis,swoole,memcached,pcov,xdebug"}

USERNAME=${USERNAME:-"automatic"}
UPDATE_RC=${UPDATE_RC:-"true"}

export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# If in automatic mode, determine if a user already exists, if not use vscode
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME=root
    USER_UID=0
    USER_GID=0
fi

architecture="$(uname -m)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

distribution=$(sed -nE 's/^ID=(.*)$/\1/p' /etc/os-release)
if [ "${distribution}" != "ubuntu" ] && [ "${distribution}" != "debian" ]; then
    echo "(!) Distribution ${distribution} unsupported"
    exit 1
fi

updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
        if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/bash.bashrc
        fi
        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            echo "Running apt-get update..."
            apt-get update -y
        fi
        apt-get -y install --no-install-recommends "$@"
    fi
}

add_repository() {

    if [[ "$distribution" == "ubuntu" ]]; then
        echo "Adding ppa ondrej/php"
        apt update
        apt install -y software-properties-common
        sudo add-apt-repository -y ppa:ondrej/php
    elif [[ "$distribution" == "debian" ]]; then
        echo "Adding dpa ondrej/php"
        apt-get -y install apt-transport-https lsb-release ca-certificates curl
        curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
        sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
    fi

    apt update
}

add_composer() {
    php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer
}

# Persistent / runtime dependencies
RUNTIME_DEPS="wget ca-certificates git build-essential xz-utils"

# Install dependencies
check_packages $RUNTIME_DEPS

# Setup repositories
add_repository


install_php() {
    echo "Installing php"
    apt install -y php${VERSION}-cli php${VERSION}-dev $(echo "$@" | sed -e 's/\([^,]*\),\?/php'"$VERSION"'-\1 /g')

    add_composer
}

install_php "${EXTENSIONS}"

# Clean up

apt -y autoremove
apt -y clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

echo "Done !"