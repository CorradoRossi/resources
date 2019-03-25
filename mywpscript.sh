#!/bin/bash

DOT_FILE="$HOME/.wordpress-base"
WORDPRESS_REPO="git@github.com:WordPress/WordPress.git"
VHOST="<VirtualHost *:80>\n
            ServerName $DEV_DOMAIN\n
            DocumentRoot "$SITE_DIRECTORY"\n
          </VirtualHost>\n"
ETC_HOSTS="/etc/hosts"
MAMP="/applications/MAMP/conf/apache/extra/httpd-vhosts.conf"
LOCAL_IP="127.0.0.1"
R='\e[1;35m'
G='\e[0;36m'
LBBG='\e[104m'
N=$(tput sgr0)

function banner() {
    printf "\n                                                                         \n"
    printf ${LBBG}
    printf "\n                                                                           "
    printf "\n  WordPress Configurator Script V 0.3                                      "
    printf "\n  ---------------------------------------------------------------------- \n"
    printf "  This script sets up a new WordPress project.                              "
    printf "\n  ---------------------------------------------------------------------- \n"
    printf "  Author: MotoRossi (hello@motorossi.me)                                   \n"
    printf "                                                                           \n"
    printf ${N}
}

function create_dot_file() {
    echo -n "What's the root directory for your projects? ${G}$HOME/${N}:\n"
    read SITE_ROOT
    if [ ! $SITE_ROOT ] || [ $SITE_ROOT == "" ]; then
        SITE_ROOT="~/Sites"
    fi
    echo "ROOT_DIR=${SITE_ROOT}" > $DOT_FILE
    printf "${G}Config file created.${N}\n"
}

function check_dot_file() {
    if [ ! -f "$DOT_FILE" ]; then
        printf "${R}Config file not found. Creating one now.${N}\n"
        create_dot_file
    fi
    source $DOT_FILE
}

function site_root_info() {
    printf "\n\n"
    printf "\n  Notice "
    printf "\n  ----------------------------------------------------------------------  \n"
    printf "  This project assumes that MAMP is installed and configured.\n"
    printf "  If not, go grab it at (${G}https://www.mamp.info/en/${N}\n"
    printf "\n\n"
    printf "  Site root is $ROOT_DIR. To change it either\n"
    printf "    - update ${G}$DOT_FILE${N} or \n"
    printf "    - delete ${G}$DOT_FILE${N}, exit the script, and run it again.\n"
    printf "\n  ----------------------------------------------------------------------  \n"
    printf "                                                                          \n\n"

}

function site_local_domain() {
    printf "  ----------------------------------------------------------------------  \n"
    printf "  What do you want for a local domain?\n"
    printf "  Use .test as a TLD for example:${G}mynewsite.test${N}\n"
    printf "    - If you're setting up a multisite, you're on your own. \n"
    printf "\n  ----------------------------------------------------------------------  \n"
    printf "                                                                          \n\n"
    printf "Set the development domain name (example mynewsite.test):"
    read DEV_DOMAIN

    if [ ! $SITE_DIRECTORY ] || [ $SITE_DIRECTORY == "" ]; then
        log "\n${R}Woops try again--make sure to use a valid TLD${N}"
        site_local_domain
        return
    fi
}

function set_vhost() {
    printf "\n  ----------------------------------------------------------------------  \n"
    printf "   \n"
    printf "   Setting virtualhost in .../apache/extra/httpd-vhosts.conf file. \n" 
    printf "   \n"
    printf "\n  ----------------------------------------------------------------------  \n"
    printf "                                                                          \n\n"
    printf "%s\t%s\n" "$VHOST" | sudo tee -a $MAMP > /dev/null
}

function set_etc_host() {
    printf "\n  ----------------------------------------------------------------------  \n"
    printf "   \n"
    printf "  Updating /etc/hosts with new virtualhost (password may be required). \n" 
    printf "   \n"
    printf "\n  ----------------------------------------------------------------------  \n"
    printf "                                                                          \n\n"
    printf "%s\t%s\n" "$LOCAL_IP" "$DEV_DOMAIN" | sudo tee -a $ETC_HOSTS > /dev/null
}

function get_and_create_site_directory() {
    echo -n "Enter the directory for your new project (it will be created in $ROOT_DIR):"
    read SITE_DIRECTORY

    if [ ! $SITE_DIRECTORY ] || [ $SITE_DIRECTORY == "" ]; then
        log "\n${R}Try again${N}"
        get_and_create_site_directory
        return
    fi

    SITE_DIRECTORY=$ROOT_DIR/$SITE_DIRECTORY

    if [ -d "$SITE_DIRECTORY" ]; then
        log "\n${R}$SITE_DIRECTORY directory already exists, hmm.${N}"
        get_and_create_site_directory
        return
    fi
    log "creating $SITE_DIRECTORY"
    mkdir $SITE_DIRECTORY
}

function clone_wordpress() {
	log "Cloning Wordpress into $SITE_DIRECTORY ..."
	cd $SITE_DIRECTORY
	git clone $WORDPRESS_REPO wordpress --depth=1
	rm -rf wordpress/.git
}

function cd_site_dir() {
	cd $SITE_DIRECTORY
}

function log() {
	printf "$1\n\n"
}

function create_config() {
    cp $SITE_DIRECTORY/wordpress/wp-config-sample.php $SITE_DIRECTORY/wordpress/wp-config.php 
}

function database_variables() {
    echo -n "Enter your database name:"
    read DATABASE_NAME

    if [ ! $DATABASE_NAME ] || [ $DATABASE_NAME == "" ]; then
        log "\n${R}Try again${N}"
        database_variables
        return
    fi

    echo -n "Enter a new database username:"
    read DATABASE_USERNAME

    if [ ! $DATABASE_USERNAME ] || [ $DATABASE_USERNAME == "" ]; then
        log "\n${R}Try again${N}"
        database_variables
        return
    fi

    echo -n "Enter a new database password:"
    read DATABASE_PASSWORD

    if [ ! $DATABASE_PASSWORD ] || [ $DATABASE_PASSWORD == "" ]; then
        log "\n${R}Try again${N}"
        database_variables
        return
    fi

    echo -n "Change sample database prefix from wp_ to:"
    read DATABASE_PREFIX

    if [ ! $DATABASE_PREFIX ] || [ $DATABASE_PREFIX == "" ]; then
        log "\n${R}Try again${N}"
        database_variables
        return
    fi
}

function find_replace() {
    log "Replacing database variables in ${G}wp-config.php${N}."
    find $SITE_DIRECTORY/wordpress/wp-config.php -type f | xargs sed -i '' "s/database_name_here/$DATABASE_NAME/g"
    find $SITE_DIRECTORY/wordpress/wp-config.php -type f | xargs sed -i '' "s/username_here/$DATABASE_USERNAME/g"
    find $SITE_DIRECTORY/wordpress/wp-config.php -type f | xargs sed -i '' "s/password_here/$DATABASE_PASSWORD/g"
    find $SITE_DIRECTORY/wordpress/wp-config.php -type f | xargs sed -i '' "s/'wp_'/'$DATABASE_PREFIX'/g"
}

function replace_salt() {
    log "Replacing authentication unique keys and salt."
    SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
    STRING='put your unique phrase here'
    printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s $SITE_DIRECTORY/wordpress/wp-config.php
}

function completed_notice() {
    printf "\n\n"
    printf "\n  Done! "
    printf "\n  ----------------------------------------------------------------------  \n"
    printf "  Next steps:\n"
    printf "  Open MAMP and create a new database with phpmyadmin using the \n" 
    printf "  database name, username, and password you entered here. \n"
    printf "  Restart MAMP and your site will be live at $DEV_DOMAIN! \n"
    printf "  - have fun! \n"
    printf "\n  ----------------------------------------------------------------------  \n"
    printf "                                                                          \n\n"
}

banner
check_dot_file
site_root_info
get_and_create_site_directory
site_local_domain
clone_wordpress
create_config
database_variables
find_replace
replace_salt
set_vhost
set_etc_host
completed_notice