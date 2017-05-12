Summary: x
Name: b
Version: 1
Release: 1
License: x
Group: x
Url: x
BuildArch: noarch

%description
x

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT/etc
echo b > $RPM_BUILD_ROOT/etc/foo

%clean
rm -rf $RPM_BUILD_ROOT

%files
/etc/*
