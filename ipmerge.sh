#!/bin/sh
set -e

ip_save()
{
    eval "${2}network${1}=${NETWORK}"
    eval "${2}prefix${1}=${PREFIX}"
    eval "${2}broadcast${1}=${BROADCAST}"
}

ip_restore()
{
    eval "NETWORK=\$${2}network${1}"
    eval "PREFIX=\$${2}prefix${1}"
    eval "BROADCAST=\$${2}broadcast${1}"
}

ip_merge()
{
    local num=0
    ip_restore __
    ip_save 2
    ip_save 2 _
    printf 'merge cycle %d ...\n' $2 >&2
    while read line
    do
        eval $(ipcalc -npb $line)
        ip_save 1
        PREFIX=$(expr $PREFIX - 1)
        eval $(ipcalc -npb $NETWORK/$PREFIX)
        if [ "$NETWORK" = "$_network2" -a "$PREFIX" = "$_prefix2" ]; then
            num=$(expr $num + 1)
            [ -n "$DEBUG" ] && printf '  merge % -19s % -19s -> % -19s\n' "$network2/$prefix2" "$network1/$prefix1" "$NETWORK/$PREFIX" >&2
            ip_save 2 _
            ip_save 2
        else
            [ -n "$network2" -a -n "$prefix2" ] && echo "$network2/$prefix2"
            ip_save 2 _
            ip_restore 1
            ip_save 2
        fi
    done < $1
    echo "$network2/$prefix2"
    printf 'merged %d blocks.\n' $num >&2
}

ip_merge_all()
{
    local from=${1}.0
    local to=${1}.1
    local i
    ip_merge $1 1 > $to
    for i in $(seq 2 24)
    do
        mv -f $to $from
        ip_merge $from $i > $to
        cmp -s $from $to && break;
    done
    cat $to
    rm -f $from $to
}

file=$1

[ -f "$file" ] || exit 1

ip_merge_all $file
