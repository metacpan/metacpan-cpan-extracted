Name:           perl-VOMS-Lite
Version:        0.20
Release:        1%{?dist}
Summary:        Perl extension for VOMS Attribute certificate creation
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/VOMS-Lite/
Source0:        ftp://ftp.funet.fi/pub/CPAN/authors/id/M/MI/MIKEJ/VOMS-Lite-%{version}.tar.gz
Source1:        voms.config
Patch0:         unwin32.patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Crypt::DES_EDE3)
BuildRequires:  perl(Digest::MD2)
BuildRequires:  perl(Digest::SHA1)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(IO::Socket::SSL)
BuildRequires:  perl(Regexp::Common)
BuildRequires:  perl(Term::ReadKey)
BuildRequires:  perl(Math::BigInt::GMP)
BuildRequires:  perl(Crypt::CBC)
Requires:       perl(Math::BigInt::GMP)
Requires:       perl(Crypt::DES_EDE3)
Requires:       perl(Digest::MD2)
Requires:       perl(Digest::SHA1)
Requires:       perl(IO::Socket::SSL)
Requires:       perl(Regexp::Common)
Requires:       perl(Term::ReadKey)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

#Add a test sub package.
%{?perl_default_subpackage_tests}

%description
VOMS (virtual organization membership service) is a system for 
managing grid level authorization data within 
multi-institutional collaborations via membership and roles
within that membership.

VOMS::Lite provides a perl library and client tools 
for interacting with an existing voms service including the 
well known C implementation of voms.

A number of commands are included for generating and processing 
proxies including  voms-proxy-init.pl, voms-ac-issue.pl, ...

Configuration of client tools can be supplied via 
$ENV{'VOMS_CONFIG_FILE'} or else ~/.grid-security/voms.conf. 
The root user only uses /etc/grid-security/voms.config.

%package -n perl-voms-server
Group:      Development/Libraries
Summary:    Perl extension for VOMS Attribute certificate creation
Requires:   perl-VOMS-Lite = %{version}-%{release} 

%description -n perl-voms-server
VOMS (virtual organization membership service) is a system for 
managing grid level authorization data within 
multi-institutional collaborations via membership and roles
within that membership.

A server voms-server.pl providing a perl implementation
of a VOMS server.

%{?perl_default_filter}
%prep

%setup -q -n VOMS-Lite-%{version}
%patch0 -p1
chmod 644 misc/PROXYINFO.pl
cp -p %{SOURCE1} .

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf %{buildroot}

make pure_install DESTDIR=%{buildroot}
# I believe the voms-server.pl was meant to be installed in 
# sbin.
mkdir %{buildroot}%{_sbindir}
mv %{buildroot}%{_bindir}/voms-server.pl %{buildroot}%{_sbindir}/voms-server.pl
mv %{buildroot}%{_bindir}/vomsserver.pl %{buildroot}%{_sbindir}/vomsserver.pl
find %{buildroot} -type f -name .packlist -exec rm -f {} \;
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} %{buildroot}/*

# Install a default configuration file and directory for VO grid-mapfiles.
mkdir -p %{buildroot}%{_sysconfdir}/grid-security/grid-mapfile.d
install -p -m 644 voms.config %{buildroot}%{_sysconfdir}/grid-security/voms.config

%check
make test

%post
# This is a masive hack but I cannot seem to get the RPM macros 
# to lose the Win32 API requirement.  We patched references to Win32 out in %prep
# now we patch them back.
cd %{perl_vendorlib}/VOMS/Lite
patch -s -R < %{_docdir}/%{name}-%{version}/misc/unwin32.patch

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc Changes README TODO misc
%{perl_vendorlib}/*
%{_mandir}/man3/*
%{_bindir}/cert-init.pl
%{_bindir}/cert-req.pl
%{_bindir}/examineAC.pl
%{_bindir}/extractVOMS.pl
%{_bindir}/myproxy-get.pl
%{_bindir}/myproxy-init.pl
%{_bindir}/proxy-init.pl
%{_bindir}/verifycert.pl
%{_bindir}/voms-ac-issue.pl
%{_bindir}/voms-proxy-init.pl
%{_bindir}/voms-proxy-list.pl
%{_mandir}/man1/cert-init.pl.1*
%{_mandir}/man1/cert-req.pl.1*
%{_mandir}/man1/examineAC.pl.1*
%{_mandir}/man1/extractVOMS.pl*
%{_mandir}/man1/myproxy-get.pl*
%{_mandir}/man1/myproxy-init.pl*
%{_mandir}/man1/proxy-init.pl*
%{_mandir}/man1/verifycert.pl*
%{_mandir}/man1/voms-ac-issue.pl.1*
%{_mandir}/man1/voms-proxy-init.pl.1*
%{_mandir}/man1/voms-proxy-list.pl.1*

%dir %{_sysconfdir}/grid-security
%dir %{_sysconfdir}/grid-security/grid-mapfile.d
%config(noreplace) %{_sysconfdir}/grid-security/voms.config

%files -n perl-voms-server
%defattr(-,root,root,-)
%{_sbindir}/voms-server.pl
%{_sbindir}/vomsserver.pl
%{_mandir}/man1/voms-server.pl.1*
%{_mandir}/man1/vomsserver.pl.1*

%changelog
* Wed Jun 29 2011 Mike Jones <mike.jones@manchester.ac.uk> 0.17-1
- New upstream 0.17
- Incorporating this spec file into VOMS::Lite source, 
  having patched out win32 before install and patched 
  it back afterwards.

* Mon Mar 21 2011 Steve Traylen <steve.traylen@cern.ch> 0.14-1
- New upstream 0.14

* Wed Mar 16 2011 Steve Traylen <steve.traylen@cern.ch> 0.12-1
- New upstream 0.12,  Add voms-proxy-list.pl as bin new 
  command and man page.

* Sun Mar 13 2011 Steve Traylen <steve.traylen@cern.ch> 0.11-1
- Update to 0.11.
- New build requires for perl(Crypt::CBC)
- Install configuration file mode 644.
- Split server application out to seperate package.

* Sat Mar 13 2010 Steve Traylen <steve.traylen@cern.ch> 0.09-5
- Rewrite summary to make it less cryptic.
- Create a -tests package when possible.
- Install configuration file at 600.

* Mon Mar 7 2010 Steve Traylen <steve.traylen@cern.ch> 0.09-4
- Move voms-server.pl to /usr/sbin
- Add a default configuration for voms-server.pl

* Sat Mar 6 2010 Steve Traylen <steve.traylen@cern.ch> 0.09-3
- Change source URL to not point at an old mirror.

* Sun Feb 21 2010 Steve Traylen <steve.traylen@cern.ch> 0.09-2
- Filter out perl(WIN32::API) with new macros where
  possible.
- Install in DESTDIR

* Tue Feb 16 2010 Steve Traylen <steve.traylen@cern.ch> 0.09-1
- Filter out perl(WIN32::API) from requires.
- Addition of perl(Math::BigInt::GMP) for speed.
- Add bins and associated man pages to file list.
- Specfile autogenerated by cpanspec 1.78.
