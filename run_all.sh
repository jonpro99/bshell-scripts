[ "$debug" ] && echo preping 01-devfunctions.sh

[ "$debug" ] && echo running 01-devfunctions.sh
source boot/01-devfunctions.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 02-start.sh
[ "$build_day" ] || build_day='20100509'
[ "$RESOLVED_INITRD_MODULES" ] || RESOLVED_INITRD_MODULES='thermal mptspi ata_piix ata_generic piix ide_pci_generic processor fan jbd ext3 edd'

modules=" $RESOLVED_INITRD_MODULES"
[ "$debug" ] && echo running 02-start.sh
source boot/02-start.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 03-storage.sh
[ "$fallback_rootdev" ] || fallback_rootdev='/dev/sda2'
[ "$rootdev" ] || rootdev='/dev/sda2'
[ "$rootfsopts" ] || rootfsopts='acl,user_xattr'

[ "$debug" ] && echo running 03-storage.sh
source boot/03-storage.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 04-udev.sh
[ "$udev_timeout" ] || udev_timeout='30'

[ "$debug" ] && echo running 04-udev.sh
source boot/04-udev.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 05-blogd.sh
if [  -x /sbin/blogd ]; then
[ "$debug" ] && echo running 05-blogd.sh
source boot/05-blogd.sh
[ "$modules" ] && load_modules
fi
[ "$debug" ] && echo preping 05-clock.sh

[ "$debug" ] && echo running 05-clock.sh
source boot/05-clock.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 11-block.sh
[ "$block_modules" ] || block_modules='mptspi sd_mod'
if [  "$block_modules" ]; then
[ "$debug" ] && echo running 11-block.sh
source boot/11-block.sh
[ "$modules" ] && load_modules
fi
[ "$debug" ] && echo preping 21-devinit_done.sh

[ "$debug" ] && echo running 21-devinit_done.sh
source boot/21-devinit_done.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 81-resume.userspace.sh
if [  -x /usr/sbin/resume -o -x /sbin/resume ]; then
[ "$debug" ] && echo running 81-resume.userspace.sh
source boot/81-resume.userspace.sh
[ "$modules" ] && load_modules
fi
[ "$debug" ] && echo preping 82-resume.kernel.sh

[ "$debug" ] && echo running 82-resume.kernel.sh
source boot/82-resume.kernel.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 83-mount.sh
[ "$rootdev" ] || rootdev='/dev/sda2'
[ "$rootfsck" ] || rootfsck='/sbin/fsck.ext3'
if [  ! "$root_already_mounted" ]; then
[ "$debug" ] && echo running 83-mount.sh
source boot/83-mount.sh
[ "$modules" ] && load_modules
fi
[ "$debug" ] && echo preping 84-remount.sh

[ "$debug" ] && echo running 84-remount.sh
source boot/84-remount.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 91-createfb.sh

[ "$debug" ] && echo running 91-createfb.sh
source boot/91-createfb.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 91-killblogd.sh

[ "$debug" ] && echo running 91-killblogd.sh
source boot/91-killblogd.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 91-killudev.sh

[ "$debug" ] && echo running 91-killudev.sh
source boot/91-killudev.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 91-shell.sh

[ "$debug" ] && echo running 91-shell.sh
source boot/91-shell.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 92-killblogd2.sh

[ "$debug" ] && echo running 92-killblogd2.sh
source boot/92-killblogd2.sh
[ "$modules" ] && load_modules
[ "$debug" ] && echo preping 93-boot.sh

modules=" "
[ "$debug" ] && echo running 93-boot.sh
source boot/93-boot.sh
[ "$modules" ] && load_modules
