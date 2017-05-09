#!/bin/bash
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

track_img() {
    info "mount: [%s]" "$2"
    mount "$@" && IMG_ACTIVE_MOUNTS=("$2" "${IMG_ACTIVE_MOUNTS[@]}")
}

mount_img() {
    IMG_ACTIVE_MOUNTS=()
    mkdir -p "$2"
    track_img "$1" "$2"
}

umount_img() {
    if [[ -n ${IMG_ACTIVE_MOUNTS[@]} ]];then
        info "umount: [%s]" "${IMG_ACTIVE_MOUNTS[@]}"
        umount "${IMG_ACTIVE_MOUNTS[@]}"
        unset IMG_ACTIVE_MOUNTS
        rm -r "$1"
    fi
}

track_fs() {
    info "overlayfs mount: [%s]" "$5"
    mount "$@" && FS_ACTIVE_MOUNTS=("$5" "${FS_ACTIVE_MOUNTS[@]}")
}

# $1: new branch
# mount_fs_root(){
#     FS_ACTIVE_MOUNTS=()
#     mkdir -p "${mnt_dir}/work"
#     mkdir -p "$1"
#     track_fs -t overlay overlay -olowerdir="${work_dir}/rootfs",upperdir="$1",workdir="${mnt_dir}/work" "$1"
# }
#
# mount_fs_desktop(){
#     FS_ACTIVE_MOUNTS=()
#     mkdir -p "${mnt_dir}/work"
#     mkdir -p "$1"
#     track_fs -t overlay overlay -olowerdir="${work_dir}/desktopfs":"${work_dir}/rootfs",upperdir="$1",workdir="${mnt_dir}/work" "$1"
# }
#
# mount_fs_live(){
#     FS_ACTIVE_MOUNTS=()
#     mkdir -p "${mnt_dir}/work"
#     mkdir -p "$1"
#     track_fs -t overlay overlay -olowerdir="${work_dir}/livefs":"${work_dir}/desktopfs":"${work_dir}/rootfs",upperdir="$1",workdir="${mnt_dir}/work" "$1"
# }
#
# mount_fs_net(){
#     FS_ACTIVE_MOUNTS=()
#     mkdir -p "${mnt_dir}/work"
#     mkdir -p "$1"
#     track_fs -t overlay overlay -olowerdir="${work_dir}/livefs":"${work_dir}/rootfs",upperdir="$1",workdir="${mnt_dir}/work" "$1"
# }
#
# mount_fs_select(){
#     local fs="$1" pkglist="$2"
#     if [[ -f "$pkglist" ]]; then
#         mount_fs_desktop "$fs"
#     else
#         mount_fs_root "$fs"
#     fi
# }
#
# mount_fs_select_boot(){
#     local fs="$1" pkglist="$2"
#     if [[ -f "$pkglist" ]]; then
#         mount_fs_live "$fs"
#     else
#         mount_fs_net "$fs"
#     fi
# }

mount_fs(){
    FS_ACTIVE_MOUNTS=()
    local lower= upper="$1" work="$2" pkglist="$3"
    local fs=${upper##*/}
    local rootfs="$work/rootfs" desktopfs="$work/desktopfs" livefs="$work/livefs"
    mkdir -p "${mnt_dir}/work"
    mkdir -p "$upper"
    case $fs in
        desktopfs) lower="$rootfs" ;;
        livefs|mhwdfs)
            lower="$rootfs"
            if [[ -f $pkglist ]];then
                lower="$desktopfs":"$rootfs"
            fi
        ;;
        bootfs)
            lower="$livefs":"$rootfs"
            if [[ -f $pkglist ]];then
                lower="$livefs":"$desktopfs":"$rootfs"
            fi
        ;;
    esac
    track_fs -t overlay overlay -olowerdir="$lower",upperdir="$upper",workdir="${mnt_dir}/work" "$upper"
}

umount_fs(){
    if [[ -n ${FS_ACTIVE_MOUNTS[@]} ]];then
        info "overlayfs umount: [%s]" "${FS_ACTIVE_MOUNTS[@]}"
        umount "${FS_ACTIVE_MOUNTS[@]}"
        unset FS_ACTIVE_MOUNTS
        rm -rf "${mnt_dir}/work"
    fi
}
