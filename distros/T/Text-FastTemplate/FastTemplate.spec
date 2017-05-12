%define	_name	Text-FastTemplate
%define _ver	0.95
%define _path	%{_name}-%{_ver}

# Provide perl-specific find-{provides,requires}.
%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

Summary: General text-template perl module.
Name: perl-%{_name}
Version: %{_ver}
Release: 1
URL: ftp://ftp.cpan.org/pub/CPAN/modules/by-module/Text/%{_path}.tar.gz
Source0: %{_path}.tar.gz
License: GPL
Group: Development/Libraries
Packager: Robert Lehr <bozzio@the-lehrs.com>
Requires: perl >= 5.005_05
BuildRoot: %{_tmppath}/%{name}-root
BuildArch: noarch

%description
Text::FastTemplate is a general text template module was specifically
designed for persistent applications.  It is optimized for speed and
simplicity.  It enforces the separation of logic and presentation.

%prep
%setup -qn %{_path}

%build
perl Makefile.PL PREFIX=$RPM_BUILD_ROOT/%{prefix}
make

%install
rm -rf $RPM_BUILD_ROOT
eval `perl '-V:installarchlib'`
mkdir -p $RPM_BUILD_ROOT/$installarchlib
make install

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

find $RPM_BUILD_ROOT/%{prefix} -type f -print | 
	sed "s@^$RPM_BUILD_ROOT@@g" | 
	grep -v perllocal.pod | 
	grep -v "\.packlist" > %{_path}-filelist
if [ "$(cat %{_path}-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit -1
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{_path}-filelist
%defattr(-,root,root)

%changelog
* Tue Oct  9 2001 Robert Lehr <bozzio@the-lehrs.com>
- Initial build.

