Summary: x
Name: p
Version: 2
Release: 1
License: x
BuildArch: noarch

%description
x

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/foo
mkdir -p $RPM_BUILD_ROOT/var
echo bar > $RPM_BUILD_ROOT/etc/foo/bar
echo boo > $RPM_BUILD_ROOT/etc/foo/boo
ln -s ../etc/foo $RPM_BUILD_ROOT/var/foo

%clean
rm -rf $RPM_BUILD_ROOT

%pretrans
if [ ! -L /var/foo ]; then
   echo "handling by hand /var/foo migration"
   mv /var/foo/* /etc/foo/
   rmdir /var/foo
   ln -s ../etc/foo /var/foo
fi

%files
/etc/foo
/var/foo


