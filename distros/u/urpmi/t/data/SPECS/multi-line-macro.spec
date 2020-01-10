%define foobar /etc/foo \
               /etc/bar

Summary: x
Name: multi-linux-macro
Version: 1
Release: 1
License: x

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc
echo foo > $RPM_BUILD_ROOT/etc/foo
echo bar > $RPM_BUILD_ROOT/etc/bar

%clean
rm -rf $RPM_BUILD_ROOT

%description
x

%files
%defattr(-,root,root)
%foobar
