Name:           perl-Time-HiRes-Sleep-Until
Version:        0.10
Release:        1%{?dist}
Summary:        Perl library which provides common ways to sleep until
License:        MIT
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Time-HiRes-Sleep-Until/
Source0:        http://www.cpan.org/modules/by-module/Time/Time-HiRes-Sleep-Until-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::Simple) >= 0.44
BuildRequires:  perl(Test::Number::Delta)
BuildRequires:  perl(Package::New)
BuildRequires:  perl(Math::Round) >= 0.05
Requires:       perl(Package::New)
Requires:       perl(Math::Round) >= 0.05
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Sleep Until provides sleep wrappers for common sleep functions that I 
typically need. These methods are simply wrappers around Time::HiRes 
and Math::Round.

%prep
%setup -q -n Time-HiRes-Sleep-Until-%{version}

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
%doc Changes LICENSE README.md
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
