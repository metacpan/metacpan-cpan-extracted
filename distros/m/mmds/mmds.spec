Summary: Minimal Markup Document System
Name: mmds
Version: 1.902
Release: 1
Distribution: Sciurix 1.0
Vendor: Squirrel Consultancy
Source: %{name}-%{version}.tar.gz
Copyright: GPL/Artistic
Group: Text/Utilities
BuildRoot: /var/tmp/mmds-buildroot
Provides: mmds
Requires: perl >= 5.6.0
Requires: tetex >= 1.0
BuildArch: noarch
AutoReqProv: off

%description
Minimal Markup Document System

%prep
%setup

%build
make

# Red Hat convention is to place configs in /etc/%{name}.
mv mmds.prp etc.mmds.prp
perl -pi -e 's;/usr/local/lib/mmds;%{_libdir}/mmds;;' \
	 -e 's;\$\{config\.mmdslib\}/texdir;%{_datadir}/mmds/texdir;;' \
    etc.mmds.prp
echo "# Process system-wide properties." >mmds.prp
echo "include %{_sysconfdir}/mmds/mmds.prp" >>mmds.prp

%install
rm -fr ${RPM_BUILD_ROOT}
%makeinstall
mkdir -p ${RPM_BUILD_ROOT}/%{_sysconfdir}/mmds
%{__install} -m 0664 etc.mmds.prp ${RPM_BUILD_ROOT}/%{_sysconfdir}/mmds/mmds.prp

%clean

%files
%defattr(-,root,root,-)
%doc examples *.prp
%dir %{_sysconfdir}/%{name}
%config %{_sysconfdir}/%{name}/mmds.prp
%{_bindir}/mmds
%dir %{_libdir}/%{name}
%config %{_libdir}/%{name}/*.prp
%{_libdir}/%{name}
%{_datadir}/%{name}

%post
%preun
%postun
%changelog
