Summary: b
Name: b
Version: 2
Release: 1
License: x

%description
x

%build
rm -rf $RPM_BUILD_ROOT
echo "installing %name" > README.install.urpmi
echo "upgrading %name" > README.upgrade.urpmi
echo "upgrading %name 2" > README.2.upgrade.urpmi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README.*
