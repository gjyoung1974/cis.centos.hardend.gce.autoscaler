#!/bin/bash -xe

APP="nginx"
APP_DIR=/opt/$APP

BUILDER_DIR="/tmp/builder"

run_command () {
    echo "Running script [$1]"
    chmod +x $1
    (cd $BUILDER_DIR/setup-scripts; BUILDER_DIR=$BUILDER_DIR $1 )
    if [ $? -ne "0" ]; then
        echo "Exiting. Failed to execute [$1]"
        exit 1
    fi
}

setup_base() {
    echo "Creating base directories for platform."
    mkdir -p $APP_DIR
    mkdir -p $APP_DIR/deploy/appsource/
    mkdir -p /opt/appdir
    mkdir -p /var/app/staging
    mkdir -p /var/app/current
    mkdir -p /var/log/nginx/healthd/
    mkdir -p /var/log/tomcat/

    echo "Setting permissions in /opt/appdir"
    find /opt/appdir -type d -exec chmod 755 {} \; -print
    chown -R root:root /opt/appdir/

    echo "Setting permissions for shell scripts"
    find /opt/appdir/ -name "*.sh" -exec chmod 755 {} \; -print
}

set_permissions() {
    echo "Setting permissions for /tmp"
    chmod 1777 /tmp
    chown root:root /tmp
}

prepare_platform_base() {
    setup_base
    set_permissions
}

sync_platform_uploads() {
    ##### COPY THE everything in platform-uploads to / ####
    echo "Setting up platform hooks"
    rsync -ar $BUILDER_DIR/platform-uploads/ /
}

run_setup_scripts() {
    for entry in $( ls $BUILDER_DIR/setup-scripts/*.sh | sort ) ; do
        run_command $entry
    done
}

run_ansible_provisioning_plays(){
    pushd $BUILDER_DIR
    echo `pwd`
    sudo mkdir -p /etc/ansible
    sudo echo 'localhost ansible_connection=local' > /etc/ansible/hosts
    echo `ansible --version`
    echo "Starting hardening and base ansible roles implementation"
    ansible-playbook /tmp/builder/tmp/playbook.yml --skip=1.1.18,1.1.19,1.2.2,1.3.1,1.3.2,1.5.4,1.7.1.5,1.7.1.6,2.1.11,2.1.6,2.1.7,2.1.8,2.1.9,2.1.10,2.2.1.1,2.2.2,2.2.3,2.2.4,2.2.5,2.2.6,2.2.7,2.2.8,2.2.9,2.2.10,2.2.11,2.2.12,2.2.13,2.2.14,2.2.15,2.2.16,2.3.1,2.3.2,2.3.3,2.3.4,2.3.5 --e \"cis_level_1_exclusions=['3.2.8','5.3.4']\"
    popd
}

cleanup() {
    echo "Done all customization of packer instance. Cleaning up"
    # yum -y clean all && sudo rm -rf /tmp/* /var/tmp/*
    rm -rf $BUILDER_DIR
}
# echo "Sync data"
# sync_platform_uploads
echo "Preparing base"
prepare_platform_base
echo "Running packer builder script"
run_setup_scripts
echo "Running ansible plays"
run_ansible_provisioning_plays
echo "Running cleanup"
cleanup
echo "Setting permissions"
set_permissions
