Summary: x
Name: ga
Version: 1
Release: 1
License: x
BuildArch: noarch

%description
x

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc
ln -s dir $RPM_BUILD_ROOT/etc/dir_symlink

%clean
rm -rf $RPM_BUILD_ROOT

%files
/etc/*
