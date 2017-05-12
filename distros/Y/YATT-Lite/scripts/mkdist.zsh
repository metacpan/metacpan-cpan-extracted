#!/bin/zsh

set -e
setopt extendedglob

function die { echo 1>&2 $*; exit 1 }

cd $0:h:h:h:h
[[ -d runyatt.lib ]] || die "Can't find runyatt.lib!"
[[ -r runyatt.lib/YATT/Lite.pm ]] || die "Can't find YATT::Lite!"
origdir=$PWD

#version=$(perl -Irunyatt.lib -MYATT::Lite -le 'print YATT::Lite->VERSION')
version=$(
    perl -Irunyatt.lib -MExtUtils::MakeMaker -le \
	'print MM->parse_version(shift)' runyatt.lib/YATT/Lite.pm
)

main=(
    -name _build -prune
    -o -name cover_db -prune
    -o -name .git -prune
    -o -name \*.bak -prune
    -o -name \*~ -prune
)

tmpdir=/tmp/_build_yatt_lite$$
mkdir -p $tmpdir

build=$tmpdir/YATT-Lite-$version
{
    # Make clean copy.
    git clone $PWD $tmpdir/yatt_lite

    cd $tmpdir/yatt_lite

    # Build MANIFEST
    [[ -r MANIFEST ]] || echo MANIFEST > MANIFEST
    print -l *~*.bak(.) > MANIFEST
    find *(/) $main -o -print >> MANIFEST
    sort MANIFEST > $origdir/MANIFEST

    # Build dist
    cpio -pd $build < $origdir/MANIFEST
    sed -i "s/^Version: .*/Version: $version/" \
	$build/vendor/redhat/perl-YATT-Lite.spec

    # Archive
    tar zcvf $build.tar.gz -C $tmpdir YATT-Lite-$version

    # Package or just copy.
    if [[ -d ~/rpmbuild/SOURCES ]]; then
	mv -vu $build.tar.gz ~/rpmbuild/SOURCES
	if (($+commands[rpmbuild])); then
	    opts=()
	    if [[ -r ~/.rpmmacros ]] &&
		grep '%_gpg_name' ~/.rpmmacros > /dev/null; then
		opts+=(--sign)
	    fi
	    LANG=C rpmbuild -ta $opts ~/rpmbuild/SOURCES/$build:t.tar.gz
	fi
    else
	mkdir _build
	mv -vu $build.tar.gz _build
    fi
} always {
    rm -rf $tmpdir
}
