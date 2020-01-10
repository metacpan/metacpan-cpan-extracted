Summary: x
Name: d
Version: 1
Release: 1
License: x
BuildArch: noarch

%description
x

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc/dir
echo d > $RPM_BUILD_ROOT/etc/dir/d

%clean
rm -rf $RPM_BUILD_ROOT

%files
/etc/*
