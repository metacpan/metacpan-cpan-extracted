Summary: x
Name: rpm-query-in-scriptlet
Version: 1
Release: 1
License: x
Group: x
Url: x
BuildRoot: %{_tmppath}/%{name}

%description
x

%install
rm -rf %buildroot
echo > list
for i in sh rpm; do
   bin=`which $i`
   echo $bin >> list
   ldd $bin | sed -e 's/^[ \t]*//' -e 's/.* => //' -e 's/ .*//' >> list
done
grep '/' list | (cd / ; cpio -pumd --dereference %buildroot)

find %buildroot

%post
echo "RPMLOCK_NOWAIT is '$RPMLOCK_NOWAIT'"
rpm -q foo
true

%files
/*
