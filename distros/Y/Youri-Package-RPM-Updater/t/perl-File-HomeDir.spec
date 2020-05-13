%define	module	File-HomeDir
%define	name	perl-%{module}
%define	version	0.58
%define	release	1

Name:		%{name}
Version:	%{version}
Release:	%{release}
Summary:	Get home directory for self or other users
License:	GPL or Artistic
Group:		Development/Perl
Url:		http://search.cpan.org/dist/%{module}/
Source:		http://www.cpan.org/modules/by-module/File/%{module}-%{version}.tar.bz2
Buildarch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}

%description
A Perl module to get home directory portably for self or other users.

%prep
%setup -n %{module}-%{version}
find lib -name *.pm | xargs chmod 644 
chmod 644 Changes

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
%make_build

%check
%{__make} test

%install
rm -rf %{buildroot}
%make_install

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%doc README Changes
%{perl_vendorlib}/File
%{_mandir}/*/*

%changelog
* Wed May 31 2006 Guillaume Rousse <guillomovitch@mandriva.org> 0.58-1
- test release
