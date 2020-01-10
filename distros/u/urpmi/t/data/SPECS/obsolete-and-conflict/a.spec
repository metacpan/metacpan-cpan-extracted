Summary: a
Name: a
Version: 1
Release: 1
License: x

%description
x

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc
echo foo > $RPM_BUILD_ROOT/etc/foo
echo bar > $RPM_BUILD_ROOT/etc/bar

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/etc/*
