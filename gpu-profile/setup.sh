#!/bin/bash

# Require root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

PARAM=$1
log_path=/var/log/gpu-profile.log
daemon_path=/usr/local/bin/gpu-profile-daemon
config_maker_path=/usr/local/bin/gpu-profile
config_path=/etc/gpu-profile/conf/default.conf
cron_path=/var/spool/cron/crontabs/root
exec_cmd="/bin/bash $daemon_path > $log_path 2>&1"
cron_job="@reboot sleep 60s && $exec_cmd"

if [ "$PARAM" = "uninstall" ]; then
  crontab -l | grep -v "$cron_job"  | crontab -
  echo "Removed cronjob"

  rm $daemon_path
  rm $config_maker_path
  echo "Removed bins"

  kill "$(ps aux | grep 'gpu-profile-daemon' | awk '{print $2}')"
  echo "Uninstalled. You might need to set the GPU clocks back, or just reboot."
  exit
fi

# Setup coolbits
nvidia-xconfig -a --cool-bits=31 --allow-empty-initial-configuration --enable-all-gpus

# Install dependencies
apt install -y jq

# Download scripts
wget https://github.com/leona/vast.ai-tools/blob/master/gpu-profile/gpu-profile-daemon.sh -P /usr/local/bin
wget https://github.com/leona/vast.ai-tools/blob/master/gpu-profile/gpu-profile.sh -P /usr/local/bin
chmod +x $daemon_path
chmod +x $config_maker_path

# Setup cronjob on boot
if ! grep -q "$cron_job" "$cron_path"; then
  echo "Cronjob doesn't exist. Creating."
  (crontab -l; echo "$cron_job") | crontab -
fi

echo "Creating default profile"
gpu-profile
echo "Finished setup. Add new config with 'gpu-profile default/image_name'"