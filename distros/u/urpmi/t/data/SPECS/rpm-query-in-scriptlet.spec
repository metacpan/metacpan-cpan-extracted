# fix warnings:
%define debug_package %{nil}

Summary: x
Name: rpm-query-in-scriptlet
Version: 1
Release: 1
License: x

%description
x

%install
rm -rf %buildroot
echo %{_libdir}/libnss3.so > list
for i in sh rpm; do
   bin=`which $i`
   echo $bin >> list
   ldd $bin | sed -e 's/^[ \t]*//' -e 's/.* => //' -e 's/ .*//' >> list
done
grep '/' list | (cd / ; cpio -pumd --dereference %buildroot)

# prelinked libraries/binaries cause rpm to abort installation on
# md5sum errors while package signature does be OK :-( :
if [ -x /usr/sbin/prelink ]; then
   for i in $(find %{buildroot}/ -type f);do /usr/sbin/prelink -u $i || : ;done
fi

find %buildroot

%post
echo "RPMLOCK_NOWAIT is '$RPMLOCK_NOWAIT'"
rpm -q foo
true

%files
/*
