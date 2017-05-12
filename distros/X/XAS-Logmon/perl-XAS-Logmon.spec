Name:           perl-XAS-Logmon
Version:        0.02
Release:        1%{?dist}
Summary:        A set of processes to monitor log files
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            http://scm.kesteb.us/git/XAS-Logmon/trunk/
Source0:        XAS-Logmon-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Test::More)
Requires:       perl(XAS) >= 0.07
Requires:       perl(XAS::Supervisor) >= 0.10
Requires:       perl(Regexp::Log::Progress) >= 0.01
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
A set of process to monitor log files.

%prep
%setup -q -n XAS-Logmon-%{version}

%build
%{__perl} Build.PL installdirs=site
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
./Build redhat --destdir $RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%post
#
#chkconfig --add supervisor

%check
./Build test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes README
%{perl_sitelib}/*
%config(noreplace) /etc/sysconfig/xas-logmon
%config(noreplace) /etc/logrotate.d/xas-logmon
%config(noreplace) /etc/xas/xas-logmon.ini
/usr/share/man/*
/usr/sbin/as-logmon
/usr/sbin/db-logmon
/usr/sbin/ns-logmon
/usr/sbin/xas-logmon
/etc/init.d/xas-logmon

%changelog
* Wed Nov 20 2013 "kesteb <kevin@kesteb.us>" 0.01-1
- Created for the v0.01 release.
