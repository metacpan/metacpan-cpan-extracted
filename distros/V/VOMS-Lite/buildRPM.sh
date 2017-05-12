#!/bin/bash
basedir=`pwd`/rpm
[ -d $basedir ] || mkdir -p $basedir
builddir=$basedir/build
specfile=misc/perl-VOMS-Lite.spec

rpm_build_macrofile=$builddir/rpmmacros
rpm_macro_files=/usr/lib/rpm/macros:/usr/lib/rpm/platform/`uname -m`-linux/macros:/etc/rpm/macros.*:/etc/rpm/macros:~/.rpmmacros:$rpm_build_macrofile
rpm_systemrc_file=`for rcf in /usr/lib/rpmrc /usr/lib/rpm/rpmrc; do [ -e $rcf ] && echo "$rcf" && break; done`
# we need --rcfile for older rpmbuild versions (< 4.6) and --macros for newer (>= 4.6)
rpmbuild_command="rpmbuild --macros=$rpm_macro_files --rcfile=$rpm_systemrc_file"
rpmresign_command="rpm --resign --macros=$rpm_macro_files --rcfile=$rpm_systemrc_file"
[ -d $builddir ] || mkdir -p $builddir
rm -rf $builddir/*
cat <<EOF > $rpm_build_macrofile
%_topdir        $basedir
%_sourcedir     %{_topdir}/build
%_specdir       %{_topdir}/build
%_tmppath       %{_topdir}/build
%_builddir      %{_topdir}/build
%_buildroot     %{_topdir}/build/%{_tmppath}/%{name}-%{version}-root
%_buildrootdir  %{_topdir}/build/BUILDROOT
%_rpmdir        %{_topdir}
%_srcrpmdir     %{_topdir}
%_rpmfilename   %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm
%packager       %(echo ${USER}@)%(hostname -f) 
EOF

name=`sed -n 's/^Name:\s*//p' $specfile`
version=`sed -n 's/^Version:\s*//p' $specfile`
pkgdir=$builddir/$name-$version

cp misc/unwin32.patch misc/voms.config $builddir
cp VOMS-Lite-$version.tar.gz $builddir
$rpmbuild_command -v -v -v -bb $specfile

rm -rf $builddir
