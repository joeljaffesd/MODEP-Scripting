#!/bin/bash

# Shell script for my Senior Project - a hardware host for Neural Amp Modeler
# https://www.neuralampmodeler.com/ 

# designed for PatchboxOS with MODEP module
# https://blokas.io/patchbox-os/docs/ 

# Reads .nam file from an external memory device, copies to disk,
# and configures pedalboard to use it

# filepath/directory variables
models_dir=/var/modep/user-files/'NAM Models'
board_path=$(grep -o '[^"]*\.pedalboard' /var/modep/last.json)
board_name=$(basename -s .pedalboard $board_path)
effect_num=$(grep -A 1 "neural-amp-modeler-lv2" "$board_path/$board_name.ttl" | grep Number - | grep -oP " \K\d+")
effect_dir="$board_path/effect-$effect_num"

# search for external memory devices
usb_part=$(lsblk -n -o NAME -p | grep -v 'mmcblk0' | tail -n +2 | awk -F/ '{print $(NF-1) "/" $NF}' | sed 's|^|/|')

# check if external partition exists
if [ -n "$usb_part" ]; then

    # mount partition at /media
    sudo mount "$usb_part" /media

    # look for .nam model and assign name to a variable
    model=$(basename $(find /media -maxdepth 1 -name "*.nam"))

    # copy $model to /var/modep/user-files/'NAM Models'
    sudo cp "/media/$model" /var/modep/user-files/'NAM Models'

    # unmounts partition
    sudo umount /media

    # search $effect_dir for .nam model and assign to variable
    current_model=$(find "$effect_dir" -name "*.nam")

    # delete $current_model if it exists
    if [ -n "$current_model" ]; then
        sudo rm $current_model 
        fi

    # copy .nam model to $effect_dir
    sudo cp "$models_dir/$model" "$effect_dir"

    # modify contents of effect.ttl
    sudo sed -i -E "s/([[:alnum:]_]+\.nam)/"$model"/g" "$effect_dir/effect.ttl"
fi
