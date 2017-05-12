Name:           perl-XAS-Service
Version:        1.00
Release:        1%{?dist}
Summary:        A set of processes to manage spool files
License:        Artistic 2.0
Group:          Development/Libraries
URL:            http://scm.kesteb.us/git/XAS-Service/trunk/
Source0:        XAS-Service-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Test::More)
Requires:       perl(JSON::XS) >= 2.32
Requires:       perl(XAS) >= 0.12
Requires:       perl(Plack) >= 1.0
Requires:       perl(Template) >= 2.18
Requires:       perl(Web::Machine) >= 0.17
Requires:       perl(Data::FormValidator) >= 4.81
Requires:       perl(POE::Filter::HTTP::Parser) >= 1.08
Requires:       perl(Data::FormValidator::Constraints::MethodsFactory) >= 0.02
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%define _initd      %{_sysconfdir}/rc.d/init.d
%define _sysconfig  %{_sysconfdir}/sysconfig
%define _logrotated %{_sysconfdir}/logrotate.d
%define _profiled   %{_sysconfdir}/profile.d
%define _xasconf    %{_sysconfdir}/xas

%if 0%{?rhel} >= 6
%{?filter_setup: %{?perl_default_filter} }
%filter_from_requires /Win32/d
%filter_from_provides /Win32/d
%filter_setup
%endif

%description
A set of processes to manage spool files

%prep
%setup -q -n XAS-Service-%{version}

%if 0%{?rhel} == 5
cat << \EOF > %{name}-prov
#!/bin/sh
%{__perl_provides} $* | sed -e '/Win32/d'
EOF
%global __perl_provides %{_builddir}/XAS-Service-%{version}/%{name}-prov
chmod +x %{__perl_provides}
cat << \EOF > %{name}-req
#!/bin/sh
%{__perl_requires} $* | sed -e '/Win32/d'
EOF
%global __perl_requires %{_builddir}/XAS-Service-%{version}/%{name}-req
chmod +x %{__perl_requires}
%endif

%build
%{__perl} Build.PL --installdirs vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install --destdir=$RPM_BUILD_ROOT create_packlist=0
./Build redhat --destdir=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;
%{_fixperms} $RPM_BUILD_ROOT/*

%check
./Build test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes README perl-XAS-Service.spec
%{perl_vendorlib}/*
%config(noreplace) %{_sysconfig}/xas-service
%config(noreplace) %{_logrotated}/xas-service
%config(noreplace) %{_initd}/xas-service
%config(noreplace) %{_xasconf}/xas-service.ini
%{_mandir}/*
%{_sbindir}/*
%{_bindir}/*

%changelog
* Tue Mar 18 2014 "kesteb <kevin@kesteb.us>" 0.01-1
- Created for the v0.01 release.
