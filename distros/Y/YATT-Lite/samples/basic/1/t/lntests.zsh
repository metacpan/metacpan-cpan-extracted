#!/bin/zsh

set -e
setopt errreturn

bindir=$(cd $0:h; print $PWD)

if ((ARGC)); then
    if [[ $1 = /* ]]; then
	destdir=$1
    else
	destdir=$PWD/$1
    fi
    shift
elif [[ -d cgi-bin ]]; then
    destdir=$PWD/t
else
    destdir=$PWD
fi

if ! [[ -d $destdir ]]; then
    mkdir -vp $destdir
    echo deny from all > $destdir/.htaccess
fi

# To make symlink relative...
function relative_link {
    local x y i j link
    x=(${(s,/,)1})
    y=(${(s,/,)2})
    for ((i = 1; i < $#x && i < $#y; i++)); do
	[[ $x[$i] = $y[$i] ]] && continue;

	# found
	link=()
	for ((j = i; j <= $#y; j++)); do
	    link+=(..)
	done
	link+=(${x[$i,$#x]})
	print ${(j,/,)link}
	return
    done

    echo 1>&2 "Can't detect relative_link for: $1 $2"
    return 1
}

link=$(relative_link $bindir $destdir)

for fn in $bindir/*.t(*); do
    if [[ -e $destdir/$fn:t ]]; then
	echo exists: $fn:t
    else
	ln -sv $link/$fn:t $destdir/$fn:t
    fi
done
