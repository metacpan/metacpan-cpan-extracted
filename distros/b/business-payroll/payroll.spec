%define perl 5.6.1
%define distro rh73

Summary: Perl Module that Provides a Payroll API.
Name: payroll
Version: 0.5
Release: 1.%{distro}
Copyright: Perl Artistic License
Group: Applications/CPAN
Source: payroll-%{version}.tar.gz
URL: http://www.pcxperience.org/
Vendor: Xperience, Inc.
Packager: James A. Pattie <james@pcxperience.com>
BuildRoot: /var/tmp/payroll-%{version}-buildroot/
BuildRequires: perl = %{perl}
Requires: perl = %{perl}, libxml2 >= 2.4.11, perl-XML-SAX >= 0.10, perl-XML-NamespaceSupport >= 1.07, perl-XML-LibXML >= 1.51, perl(File::Temp) >= 0.12

%description
Payroll is a series of Perl Modules that provides an API for working with
multiple countries federal, state and local taxes.  It also supports calculating
mileage reimbursement values and can handle adjustment entries.

The Payroll module starts with an xml document in the Input format and if 
everything is successfull, outputs the results in the Output XML format.

Currently only the US is supported and MO is the only supported state.  We are
not supporting any cities in MO yet.  Federal Income, FICA, Medicare and 
Mileage Rates are all being calculated.  We take into account the number of
allowances people can claim and the fact that you can with hold more for 
federal and state.

Federal Income tables are only available for any date >= 07/01/2001.

See the payroll_test.pl and input.xml files in the documentation directory
for a sample implementation.

/usr/bin/process_payroll is the script we recommend you use to actually do
payroll processing if you don't want to roll your own handler, etc.

# Provide perl-specific find-{provides, requires}.
%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

%prep
%setup -q

%build
CFLAGS="$RPM_OPT_FLAGS" perl Makefile.PL PREFIX=$RPM_BUILD_ROOT/usr
make

%clean
rm -rf $RPM_BUILD_ROOT

%install
rm -rf $RPM_BUILD_ROOT
eval `perl '-V:installarchlib'`
mkdir -p $RPM_BUILD_ROOT/$installarchlib
mkdir -p $RPM_BUILD_ROOT/usr/bin
make PREFIX=$RPM_BUILD_ROOT/usr install
install process_payroll $RPM_BUILD_ROOT/usr/bin

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

find $RPM_BUILD_ROOT/usr -type f -print | 
	sed "s@^$RPM_BUILD_ROOT@@g" | 
	grep -v perllocal.pod | 
	grep -v "payroll_test.pl" |
	grep -v "process_payroll" |
	grep -v "\.packlist" > payroll-%{version}-filelist
if [ "$(cat payroll-%{version}-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit -1
fi

%files -f payroll-%{version}-filelist
%defattr(-,root,root)
%doc Changes
%doc README
%doc LICENSE
%doc test
%doc docs
/usr/bin/process_payroll

%changelog
* Wed Jun 25 2003 JT Moree <james@pcxperience.com> - 0.4-1
- Cleaned up the test files location, etc.

* Tue Jun 24 2003 JT Moree <moreejt@pcxperience.com> - 0.3-1
- Changed the data storage to fix married obfuscation.

* Fri Mar 21 2003 James A. Pattie <james@pcxperience.com> - 0.2-2
- Added the process_payroll script to the distro.

* Thu Mar 20 2003 James A. Pattie <james@pcxperience.com> - 0.2-1
- Updated to version 0.2.

* Fri Oct 11 2002 James A. Pattie <james@pcxperience.com>
- Initial version.
