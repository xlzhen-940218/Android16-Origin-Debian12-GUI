#!/bin/bash
sudo sed -i 's/bookworm/trixie/g' /etc/apt/sources.list

sudo find /etc/apt/sources.list.d -type f -exec sed -i 's/bookworm/trixie/g' {} \;

sudo apt update && sudo apt dist-upgrade --autoremove -y
