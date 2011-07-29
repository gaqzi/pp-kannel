#!/bin/sh
sudo apt-get install usb-modeswitch libusb-dev libreadline-ruby1.8 libruby1.8 libopenssl-ruby ruby1.8-dev ruby1.8 ri1.8 rdoc1.8 irb1.8 libxslt-dev libxml2-dev rubygems
sudo dpkg -i ext/kannel_1.5.0-0_i386.deb ext/kannel-extras_1.5.0-0_i386.deb
sudo gem install nokogiri
sudo cp etc/usb_modeswitch.conf /etc/
sudo cp etc/udev-rules/* /etc/udev/rules.d/
sudo cp -R etc/kannel /etc/
sudo cp etc/default.kannel /etc/default/kannel
sudo install bin/modem-symlink-add.rb  bin/logrotate-kannel bin/modem-symlink-remove.sh bin/kannel-manage-smsc.rb -t /usr/local/bin
sudo mkdir -p /usr/local/lib/kannel && install lib/kannel/* /usr/local/lib/kannel
sudo install lib/kannel -t /usr/local/lib/
sudo restart udev
sudo usermod -a -G dialout kannel
sudo mkdir -p /var/spool/kannel ; chown kannel /var/spool/kannel
sudo cp etc/init.d.kannel /etc/init.d/kannel ; chmod +x /etc/init.d/kannel
sudo cp etc/kannel-manage-smsc.yml /etc/
# sudo /etc/init.d/kannel restart
