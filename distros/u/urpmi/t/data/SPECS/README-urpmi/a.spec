Summary: a
Name: a
Version: 1
Release: 1
License: x

%description
x

%prep
rm -rf *
echo "installing/upgrading %name" > README.urpmi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README.urpmi
