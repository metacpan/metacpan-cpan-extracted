Name:           perl-URL-Signature-Google-Maps-API
Version:        0.02
Release:        1%{?dist}
Summary:        Sign URLs for use with Google Maps API Enterprise Business Accounts
License:        Distributable, see LICENSE
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/URL-Signature-Google-Maps-API/
Source0:        http://www.cpan.org/modules/by-module/URL/URL-Signature-Google-Maps-API-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Config::IniFiles)
BuildRequires:  perl(Digest::HMAC_SHA1)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Package::New)
BuildRequires:  perl(Path::Class)
BuildRequires:  perl(Test::Simple) >= 0.44
Requires:       perl(Config::IniFiles)
Requires:       perl(Digest::HMAC_SHA1)
Requires:       perl(Package::New)
Requires:       perl(Path::Class)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Generates a signed URL for use in the Google Maps API. The Google
Enterprise keys can be stored in an INI file (i.e. /etc/google.conf) or
passed on assignment..

%prep
%setup -q -n URL-Signature-Google-Maps-API-%{version}

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
