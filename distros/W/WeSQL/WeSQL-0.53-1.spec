%define ver     0.53
%define rel     1
%define name    WeSQL
%define rlname  %{name}
%define source0 http://wesql.org/%{name}-%{ver}.tar.gz
%define url     http://www.wesql.org/
%define group   System Environment/Libraries
%define copy    GPL
%define filelst %{name}-%{ver}-files
%define confdir /etc
%define rhprefix  /usr
%define prefix  /usr/local
%define arch    noarch

Summary: Apache mod_perl library for embedding SQL in HTML

Name: %name
Version: %ver
Release: %rel
Copyright: %{copy}
Packager: Ward Vandewege <w@wesql.org>
Source: %{source0}
URL: %{url}
Group: %{group}
BuildArch: %{arch}
Buildroot: %{_tmppath}/%{name}-%{ver}-buildroot
Requires: perl


%description
The Web-enabled SQL (WeSQL) Apache mod_perl module is an extension to HTML, acting as a glue between HTML and SQL. It allows the use of pure SQL queries directly in HTML files, embedded in a special tag. WeSQL translates the special tags into pure HTML, so using WeSQL is transparant for the browser. WeSQL is aimed at rapid web-database integration. WeSQL is written entirely in Perl and currently supports both MySQL and PostgreSQL as backend SQL databases.

%prep
%setup

%build
perlversion=$(perl -V:version | sed -e "s@version='@@g" -e "s@';@@g")
if [ $(perl -e 'print index($INC[0],"%{rhprefix}/lib/perl");') -eq 0 ];then
    # package is to be installed in rh perl root
    inst_method="makemaker-rhroot"
    CFLAGS=$RPM_OPT_FLAGS 
		perl Makefile.PL PREFIX=$RPM_BUILD_ROOT%{rhprefix} LIB=$RPM_BUILD_ROOT%{rhprefix}/lib/perl5/site_perl/$perlversion
elif [ $(perl -e 'print index($INC[0],"%{prefix}/lib/perl");') -eq 0 ];then
    # package is to be installed in standard perl root
    inst_method="makemaker-root"
    CFLAGS=$RPM_OPT_FLAGS
		perl Makefile.PL PREFIX=$RPM_BUILD_ROOT%{prefix} LIB=$RPM_BUILD_ROOT%{prefix}/lib/perl5/site_perl/$perlversion
else
    # package must go somewhere else (eg. /opt), so leave off the perl
    # versioning to ease integration with automatic profile generation scripts
    # if this is really a perl-version dependant package you should not omit
    # the version info...
    inst_method="makemaker-site"
    CFLAGS=$RPM_OPT_FLAGS 
		perl Makefile.PL PREFIX=$RPM_BUILD_ROOT%{rhprefix} LIB=$RPM_BUILD_ROOT%{rhprefix}/lib/perl5
fi

echo $inst_method > inst_method

# get number of processors for parallel builds on SMP systems
numprocs=`cat /proc/cpuinfo | grep processor | wc | cut -c7`
if [ "x$numprocs" = "x" -o "x$numprocs" = "x0" ]; then
  numprocs=1
fi

make "MAKE=make -j$numprocs"

mkdir html/WeSQL
pod2html lib/Apache/WeSQL.pm > html/WeSQL.html
pod2html lib/Apache/WeSQL/Journalled.pm > html/WeSQL/Journalled.html
pod2html lib/Apache/WeSQL/SqlFunc.pm > html/WeSQL/SqlFunc.html
pod2html lib/Apache/WeSQL/Display.pm > html/WeSQL/Display.html
pod2html lib/Apache/WeSQL/AppHandler.pm > html/WeSQL/AppHandler.html
pod2html lib/Apache/WeSQL/Auth.pm > html/WeSQL/Auth.html

%install
rm -rf $RPM_BUILD_ROOT

make install

%__os_install_post
find $RPM_BUILD_ROOT -type f -print|sed -e "s@^$RPM_BUILD_ROOT@@g" > %{filelst}

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{filelst}
%doc COPYING README CREDITS addressbook html utils %{name}-%{ver}-%{rel}.spec

%changelog
* Tue May 28 2002 Ward Vandewege <w@wesql.org>
	Updated to version 0.53
* Wed May 19 2002 Ward Vandewege <w@wesql.org>
	Updated to version 0.52
* Sun Feb 10 2002 Ward Vandewege <w@wesql.org>
	Updated to version 0.51
* Tue Nov 20 2001 Ward Vandewege <w@wesql.org>
  Edited from Glade-Perl.spec by Dermot Musgrove <dermot@glade.perl.connectfree.co.uk>

