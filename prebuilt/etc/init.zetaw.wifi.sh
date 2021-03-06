#!/system/bin/sh
# Copyright (c) 2010-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# This script will load and unload the wifi driver to put the wifi in
# in deep sleep mode so that there won't be voltage leakage.
# Loading/Unloading the driver only incase if the Wifi GUI is not going
# to Turn ON the Wifi. In the Script if the wlan driver status is
# ok(GUI loaded the driver) or loading(GUI is loading the driver) then
# the script won't do anything. Otherwise (GUI is not going to Turn On
# the Wifi) the script will load/unload the driver
# This script will get called after post bootup.

target="$1"
serialno="$2"

btsoc=""

# No path is set up at this point so we have to do it here.
PATH=/sbin:/system/sbin:/system/bin:/system/xbin
export PATH

# Trigger WCNSS platform driver
trigger_wcnss()
{
    # We need to trigger WCNSS platform driver, WCNSS driver
    # will export a file which we must touch so that the
    # driver knows that userspace is ready to handle firmware
    # download requests.

    # See if an appropriately named device file is present
    # to explict wcnssnode device for wlan up in AU90 migration (LG do not use wcnss_serivce)
    wcnssnode=`ls /dev/wcnss_wlan`
    # wqwcnssnode=`ls /dev/wcnss*`
    case "$wcnssnode" in
        *wcnss*)
            # Before triggering wcnss, let it know that
            # caldata is available at userspace.
            if [ -e /data/misc/wifi/WCNSS_qcom_wlan_cal.bin ]; then
                calparm=`ls /sys/module/wcnsscore/parameters/has_calibrated_data`
                if [ -e $calparm ] && [ ! -e /data/misc/wifi/WCN_FACTORY ]; then
                    echo 1 > $calparm
                fi
            fi
            # There is a device file.  Write to the file
            # so that the driver knows userspace is
            # available for firmware download requests
            echo 1 > $wcnssnode
            ;;

        *)
            # There is not a device file present, so
            # the driver must not be available
            echo "No WCNSS device node detected"
            ;;
    esac

    # Plumb down the device serial number
    if [ -f /sys/devices/*wcnss-wlan/serial_number ]; then
        cd /sys/devices/*wcnss-wlan
        echo $serialno > serial_number
        cd /
    elif [ -f /sys/devices/platform/wcnss_wlan.0/serial_number ]; then
        echo $serialno > /sys/devices/platform/wcnss_wlan.0/serial_number
    fi
}

#case "$target" in
#    msm8974* | msm8226* | msm8610*)

    wlanchip=""

      echo "The WLAN Chip ID is $wlanchip"
#      case "$wlanchip" in

#      *)
      echo "*** WI-FI chip ID is not specified in /persist/wlan_chip_id **"
      echo "*** Use the default WCN driver.                             **"
      setprop wlan.driver.ath 0
      rm  /system/lib/modules/wlan.ko
      ln -s /system/lib/modules/pronto/pronto_wlan.ko \
		/system/lib/modules/wlan.ko
		
      # Populate the writable driver configuration file
      #if [ ! -e /data/misc/wifi/WCNSS_qcom_cfg.ini ]; then
          rm /data/misc/wifi/WCNSS_qcom_cfg.ini
          cp /system/etc/wifi/WCNSS_qcom_cfg.ini \
		/data/misc/wifi/WCNSS_qcom_cfg.ini
          chown system:wifi /data/misc/wifi/WCNSS_qcom_cfg.ini
          chmod 660 /data/misc/wifi/WCNSS_qcom_cfg.ini
      #fi
          rm /data/misc/wifi/WCNSS_qcom_wlan_nv.bin
          cp /system/etc/wifi/WCNSS_qcom_wlan_nv.bin \
		/data/misc/wifi/WCNSS_qcom_wlan_nv.bin
          chown system:wifi /data/misc/wifi/WCNSS_qcom_wlan_nv.bin
          chmod 660 /data/misc/wifi/WCNSS_qcom_wlan_nv.bin


      # The property below is used in Qcom SDK for softap to determine
      # the wifi driver config file
      setprop wlan.driver.config /data/misc/wifi/WCNSS_qcom_cfg.ini

      rm /etc/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin
      ln -s /data/misc/wifi/WCNSS_qcom_wlan_nv.bin \
	            /etc/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin

      rm /etc/firmware/wlan/prima/WCNSS_qcom_cfg.ini
      ln -s /data/misc/wifi/WCNSS_qcom_cfg.ini \
	            /etc/firmware/wlan/prima/WCNSS_qcom_cfg.ini

      # Trigger WCNSS platform driver
      trigger_wcnss &
#      ;;
#      esac
#      ;;
#    *)
#      ;;
#esac

# Run audio init script
/system/bin/sh /system/etc/init.zetaw.audio.sh "$target" "$btsoc"
