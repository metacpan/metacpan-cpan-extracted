#
# spec file for package Hardware-UPS-Perl
#
# Copyright (c) 2007 Christian Reile, Unterschleissheim, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments to Christian.Reile@t-online.de
#

# neededforbuild  perl
# usedforbuild    aaa_base acl attr audit-libs autoconf automake bash bind-libs bind-utils binutils bison bzip2 coreutils cpio cpp cpp41 cracklib cvs cyrus-sasl db deb diffutils e2fsprogs file filesystem fillup findutils flex gawk gcc gcc41 gdbm gdbm-devel gettext gettext-devel glibc glibc-devel glibc-locale gpm grep groff gzip html2text info insserv klogd less libacl libattr libcom_err libgcc41 libltdl libmudflap41 libnscd libstdc++41 libtool libvolume_id libxcrypt libzio linux-kernel-headers m4 make man mktemp module-init-tools ncurses ncurses-devel net-tools netcfg openldap2-client openssl pam pam-modules patch perl permissions popt procinfo procps psmisc pwdutils rcs readline rpm sed strace sysvinit tar tcpd texinfo timezone unzip update-alternatives util-linux vim zlib zlib-devel

Name:          perl-Hardware-UPS-Perl
BuildRequires: perl
License:       GNU General Public License (GPL)/Artistic License
Group:         Hardware/UPS
Provides:      Hardware::UPS::Perl
PreReq:        %insserv_prereq
Requires:      perl = %{perl_version}
Conflicts:     apcupsd nut
Autoreqprov:   on
Version:       0.43
Release:       1
Distribution:  SuSE Linux 10.1 (i586)
URL:           -
Summary:       Perl module and scripts to deal with an UPS
Source:        %{name}-%{version}.tar.gz
Vendor:        Christian Reile, Unterschleissheim, Germany
Packager:      Christian Reile <Christian.Reile@t-online.de>
BuildRoot:     %{_tmppath}/%{name}-%{version}-build

%description
Perl modules and scripts to deal with an UPS using an Hardware::UPS::Perl
driver. So far, the Megatec protocol is supported only. This
package was developed and tested using a TRUST PW-4120M UPS.

Authors:
--------
    Christian Reile <christian.reile@t-online.de>

%debug_package
%prep
%setup -q -n %{name}-%{version}

%build
perl Makefile.PL
make
make test

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install_vendor
%perl_process_packlist

%post
%{fillup_and_insserv -f -n upsperld}

%preun
%{stop_on_removal upsperld}

%postun
%{restart_on_update upsperld}
%{insserv_cleanup}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc Changes COPYING MANIFEST README TODO
%doc %{_mandir}/man?/*
%{perl_vendorarch}/auto/Hardware/UPS/Perl
%{perl_vendorlib}/Hardware/UPS/Perl
/var/adm/perl-modules/%{name}
%{_bindir}/upsadm.pl
%{_bindir}/upsagent.pl
%{_bindir}/upsstat.pl
%{_bindir}/upswatch.pl
%{_sbindir}/rcupsperld
/etc/init.d/upsperld
%config(noreplace) /etc/sysconfig/upsperld

%changelog -n perl-Hardware-UPS-Perl
* Tue Apr 17 2007 - Christian.Reile@t-online.de
- upgrade to version 0.43
  testing added
* Sat Apr 14 2007 - Christian.Reile@t-online.de
- upgrade to version 0.42
- upgrade to version 0.41
* Sat Apr 07 2007 - Christian.Reile@t-online.de
- upgrade to version 0.40
  scripts upsadm.pl and upsstat.pl added
* Sun Feb 05 2007 - Christian.Reile@t-online.de
- upgrade to version 0.30
  installation makes now a install_vendor
* Sun Jan 28 2007 - Christian.Reile@t-online.de
- upgrade to version 0.20
* Sun Jan 21 2007 - Christian.Reile@t-online.de
- initial version
