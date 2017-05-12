Summary: x
Name: e
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
ln -s d $RPM_BUILD_ROOT/etc/dir

%clean
rm -rf $RPM_BUILD_ROOT

%files
/etc/*
