Summary: d_
Name: d_
Version: 1
Release: 1
License: x
Obsoletes: d <= 1
Provides: d > 1

%description
x

%build
rm -rf $RPM_BUILD_ROOT
echo "installing %name" > README.install.urpmi
echo "upgrading %name" > README.upgrade.urpmi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README.install.urpmi README.upgrade.urpmi
