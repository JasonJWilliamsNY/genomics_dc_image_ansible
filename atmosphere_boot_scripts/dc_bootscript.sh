#!/bin/bash -x

# irsync script
#
main ()
{
    #
    # This is the main function -- These lines will be executed each run
    #

    init_irods
    inject_atmo_vars
    copy_dc_home_datasets
    add_vnc_permissions
}

inject_atmo_vars ()
{
    #
    #
    #NOTE: For now, only $ATMO_USER will be provided to script templates (In addition to the standard 'env')
    #
    #

    # Source the .bashrc -- this contains $ATMO_USER
    PS1='HACK to avoid early-exit in .bashrc'
    . ~/.bashrc
    if [ -z "$ATMO_USER" ]; then
        echo 'Variable $ATMO_USER is not set in .bashrc! Abort!'
        exit 1 # 1 - ATMO_USER is not set!
    fi
    echo "Found user: $ATMO_USER"
}

copy_dc_home_datasets ()
{
  # Performs an irsync command to copy a test dataset folder to $ATMO_USER
  # desktop
  irsync -rs i:/iplant/home/shared/cyverse_training/workshop_materials/genomics_data_carpentry_1_0_release/ /scratch >/var/log/williams_bootscript.log 2>&1
  chown -R dcuser /scratch
  cp -rs /scratch/* /home/dcuser
  chown -R dcuser /home/dcuser


}

add_vnc_permissions ()
{
    # add dcuser as an authorized user to desktop
    if grep -q "dcuser" /etc/vnc/config.custom
        then
            echo "dcuser already added"
            runuser -l $ATMO_USER -c "vncserver -kill :1"
            runuser -l dcuser -c vncserver
        else
            echo "adding dcuser"
            sed '/^Permissions/ s/$/,dcuser:f/' /etc/vnc/config.custom > /etc/vnc/config.custom.tmp && mv /etc/vnc/config.custom.tmp /etc/vnc/config.custom
            runuser -l $ATMO_USER -c "vncserver -kill :1"
            runuser -l dcuser -c vncserver
    fi
}

init_irods ()
{
	if [ ! -d "$HOME/.irods" ]; then
		mkdir -p $HOME/.irods
	fi

	if [ ! -e "$HOME/.irods/irods_environment.json" ]; then
		cat << EOF > $HOME/.irods/irods_environment.json
{
    "irods_host": "data.iplantcollaborative.org",
    "irods_zone_name": "iplant",
    "irods_port": 1247,
    "irods_user_name": "anonymous"
}
EOF
	fi

}
# This line will start the execution of the script
main
