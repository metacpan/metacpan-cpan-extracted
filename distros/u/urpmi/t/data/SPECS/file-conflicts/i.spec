Summary: x
Name: i
Version: 1
Release: 1
License: x
BuildArch: noarch

%description
x

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/share/man
echo i > $RPM_BUILD_ROOT/usr/share/man/foo

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/share/man/foo*

