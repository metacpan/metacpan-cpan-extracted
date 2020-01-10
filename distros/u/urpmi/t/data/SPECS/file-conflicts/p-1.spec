Summary: x
Name: p
Version: 1
Release: 1
License: x
BuildArch: noarch

%description
x

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/foo
mkdir -p $RPM_BUILD_ROOT/var/foo
echo bar > $RPM_BUILD_ROOT/etc/foo/bar
echo boo > $RPM_BUILD_ROOT/var/foo/boo

%clean
rm -rf $RPM_BUILD_ROOT

%files
/etc/foo
/var/foo


