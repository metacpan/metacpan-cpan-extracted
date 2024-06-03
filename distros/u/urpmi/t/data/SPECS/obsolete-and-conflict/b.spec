Summary: b
Name: b
Version: 1
Release: 1
License: x
Provides: a > 1
Obsoletes: a <= 1
Requires: c
# Fix build with rpm-4.20:
BuildArch: noarch

%description
x

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc
echo foo > $RPM_BUILD_ROOT/etc/foo

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/etc/*
