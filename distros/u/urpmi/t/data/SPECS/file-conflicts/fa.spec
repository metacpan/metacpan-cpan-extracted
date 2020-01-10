Summary: x
Name: fa
Version: 1
Release: 1
License: x
BuildArch: noarch

%description
x

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc
ln -s fa $RPM_BUILD_ROOT/etc/foo

%clean
rm -rf $RPM_BUILD_ROOT

%files
%ghost /etc/foo
