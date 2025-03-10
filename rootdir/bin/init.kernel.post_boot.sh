#=============================================================================
# Copyright (c) 2019-2022 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
# Copyright (c) 2009-2012, 2014-2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

function configure_zram_parameters() {
	# Moto yangbq2: Skip this if we are using zram from fstab.
	using_zram_from_fstab=`getprop ro.boot.using_zram_from_fstab`
	if [ "$using_zram_from_fstab" == "true" ]; then
		return
	fi
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}

	# Zram disk - 75% for < 2GB devices .
	# For >2GB Non-Go devices, size = 50% of RAM size. Max 4GB.

	let RamSizeGB="( $MemTotal / 1048576 ) + 1"
	diskSizeUnit=M
	if [ $RamSizeGB -le 2 ]; then
		let zRamSizeMB="( $RamSizeGB * 1024 ) * 3 / 4"
	else
		let zRamSizeMB="( $RamSizeGB * 1024 ) / 2"
	fi

	if [ $zRamSizeMB -gt 4096 ]; then
		let zRamSizeMB=4096
	fi

	# And enable lz4 zram compression for Go targets.
	low_ram=`getprop ro.config.low_ram`
	if [ "$low_ram" == "true" ]; then
		echo lz4 > /sys/block/zram0/comp_algorithm
	fi

	if [ -f /sys/block/zram0/disksize ]; then
		if [ -f /sys/block/zram0/use_dedup ]; then
			echo 1 > /sys/block/zram0/use_dedup
		fi
		echo "$zRamSizeMB""$diskSizeUnit" > /sys/block/zram0/disksize

		# ZRAM may use more memory than it saves if
		# SLAB_STORE_USER debug option is enabled.
		if [ -e /sys/kernel/slab/zs_handle ]; then
			echo 0 > /sys/kernel/slab/zs_handle/store_user
		fi
		if [ -e /sys/kernel/slab/zspage ]; then
			echo 0 > /sys/kernel/slab/zspage/store_user
		fi

		mkswap /dev/block/zram0
		swapon /dev/block/zram0 -p 32758
	fi
}

function configure_read_ahead_kb_values() {
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}

	dmpts=$(ls /sys/block/*/queue/read_ahead_kb | grep -e dm -e mmc -e sd)
	# dmpts holds below read_ahead_kb nodes if exists:
	# /sys/block/dm-0/queue/read_ahead_kb to /sys/block/dm-10/queue/read_ahead_kb
	# /sys/block/sda/queue/read_ahead_kb to /sys/block/sdh/queue/read_ahead_kb

	# Set 128 for <= 4GB &
	# set 512 for >= 5GB targets.
	if [ $MemTotal -le 4194304 ]; then
		ra_kb=128
	else
		ra_kb=512
	fi
	for dm in $dmpts; do
		if [ `cat $(dirname $dm)/../removable` -eq 0 ]; then
			echo $ra_kb > $dm
		fi
	done
	if [ -f /sys/block/mmcblk0/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0/bdi/read_ahead_kb
	fi
	if [ -f /sys/block/mmcblk0rpmb/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
	fi
}

function configure_memory_parameters() {
	configure_zram_parameters
	configure_read_ahead_kb_values

	echo 100 > /proc/sys/vm/swappiness

	# Disable periodic kcompactd wakeups. We do not use THP, so having many
	# huge pages is not as necessary.
	echo 0 > /proc/sys/vm/compaction_proactiveness
	# With THP enabled, the kernel greatly increases min_free_kbytes over its
	# default value. Disable THP to prevent resetting of min_free_kbytes
	# value during online/offline pages.
	if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
		echo never > /sys/kernel/mm/transparent_hugepage/enabled
	fi

	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}
	let RamSizeGB="( $MemTotal / 1048576 ) + 1"

	# Set the min_free_kbytes to standard kernel value
	if [ $RamSizeGB -ge 8 ]; then
		echo 11584 > /proc/sys/vm/min_free_kbytes
	elif [ $RamSizeGB -ge 4 ]; then
		echo 8192 > /proc/sys/vm/min_free_kbytes
	elif [ $RamSizeGB -ge 2 ]; then
		echo 5792 > /proc/sys/vm/min_free_kbytes
	else
		echo 4096 > /proc/sys/vm/min_free_kbytes
	fi
	# Disable wsf for all targets beacause we are using efk.
	# wsf Range : 1..1000 So set to bare minimum value 1.
	echo 1 > /proc/sys/vm/watermark_scale_factor

	#Set per-app max kgsl reclaim limit and per shrinker call limit
	if [ -f /sys/class/kgsl/kgsl/page_reclaim_per_call ]; then
		echo 38400 > /sys/class/kgsl/kgsl/page_reclaim_per_call
	fi
	if [ -f /sys/class/kgsl/kgsl/max_reclaim_limit ]; then
		echo 25600 > /sys/class/kgsl/kgsl/max_reclaim_limit
	fi
}

# Set Memory parameters.
configure_memory_parameters

if [ -f /sys/devices/soc0/soc_id ]; then
	platformid=`cat /sys/devices/soc0/soc_id`
fi

case "$platformid" in
	"537" | "583" | "613")
		/vendor/bin/sh /vendor/bin/init.kernel.post_boot-parrot.sh
		;;
	"568" | "602" | "581" | "582")
		/vendor/bin/sh /vendor/bin/init.kernel.post_boot-ravelin.sh
		;;
	*)
		echo "***WARNING***: Invalid SoC ID\n\t No postboot settings applied!!\n"
		;;
esac

