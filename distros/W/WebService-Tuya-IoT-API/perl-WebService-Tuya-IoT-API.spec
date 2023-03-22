Name:           perl-WebService-Tuya-IoT-API
Version:        0.03
Release:        1%{?dist}
Summary:        Perl library to access the Tuya IoT API
License:        MIT
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/WebService-Tuya-IoT-API/
Source0:        http://www.cpan.org/modules/by-module/WebService/WebService-Tuya-IoT-API-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Data::UUID)
BuildRequires:  perl(Digest::SHA)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(HTTP::Tiny)
BuildRequires:  perl(JSON::XS)
BuildRequires:  perl(Time::HiRes)
BuildRequires:  perl(List::Util)
Requires:       perl(Data::UUID)
Requires:       perl(Digest::SHA)
Requires:       perl(HTTP::Tiny)
Requires:       perl(JSON::XS)
Requires:       perl(Time::HiRes)
Requires:       perl(List::Util)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Perl library to access the Tuya IoT API to control and read the state of
Tuya compatible smart devices.

%prep
%setup -q -n WebService-Tuya-IoT-API-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc LICENSE
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
