Name:           perl-WebService-Whistle-Pet-Tracker-API
Version:        0.03
Release:        2%{?dist}
Summary:        Perl interface to access the Whistle Pet Tracker Web Service
License:        MIT
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/WebService-Whistle-Pet-Tracker-API/
Source0:        http://www.cpan.org/modules/by-module/WebService/WebService-Whistle-Pet-Tracker-API-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(HTTP::Tiny)
BuildRequires:  perl(JSON::XS)
Requires:       perl(HTTP::Tiny)
Requires:       perl(JSON::XS)
Requires:       systemd
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Perl interface to access the Whistle Pet Tracker Web Service

%package mqtt
Summary:        Publish Whistle Pet Tracker pet data to MQTT
Requires:       %{name} = %{version}-%{release}
Requires:       perl(Net::MQTT::Simple)
Requires:       perl(Tie::IxHash)
Requires:       perl(Time::HiRes)

%description mqtt
perl-WebService-Whistle-Pet-Tracker-API-mqtt.pl is a command line utility which connects to the configured MQTT broker and publishes pet data from the Whistle Pet Tracker API.

%prep
%setup -q -n WebService-Whistle-Pet-Tracker-API-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

#Add timer and service files for mqtt script
mkdir -p                                        $RPM_BUILD_ROOT/%{_unitdir}/
cp systemd/%{name}-mqtt.service                 $RPM_BUILD_ROOT/%{_unitdir}/
cp systemd/%{name}-mqtt.timer                   $RPM_BUILD_ROOT/%{_unitdir}/

#Add systemd variable override file
#`sudo systemctl edit perl-WebService-Whistle-Pet-Tracker-API-mqtt`
mkdir -p                                        $RPM_BUILD_ROOT/%{_sysconfdir}/systemd/system/%{name}-mqtt.service.d/
cp systemd/%{name}-mqtt.service.d/override.conf $RPM_BUILD_ROOT/%{_sysconfdir}/systemd/system/%{name}-mqtt.service.d/

%{_fixperms} $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%post mqtt
systemctl daemon-reload

%postun mqtt
systemctl daemon-reload

%files
%defattr(-,root,root,-)
%doc LICENSE
%{perl_vendorlib}/*
%{_mandir}/man3/*
%{_mandir}/man1/%{name}-pets.pl*
%{_mandir}/man1/%{name}-device.pl*
%{_bindir}/%{name}-pets.pl
%{_bindir}/%{name}-device.pl

%files mqtt
%defattr(-,root,root,-)
%attr(0644,root,root) %{_unitdir}/*
%dir %attr(0755,root,root) %{_sysconfdir}/systemd/system/%{name}-mqtt.service.d/
%config(noreplace) %attr(0644,root,root) %{_sysconfdir}/systemd/system/%{name}-mqtt.service.d/override.conf
%{_bindir}/%{name}-mqtt.pl
%{_mandir}/man1/%{name}-mqtt.pl*

%changelog
