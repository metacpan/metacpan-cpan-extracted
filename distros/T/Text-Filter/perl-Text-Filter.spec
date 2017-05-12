%define modname Text-Filter
%define modversion 1.10
%define modpath authors/id/J/JV/JV/%{modname}-%{modversion}.tar.gz
%define modreq perl

Name: perl-%{modname}
Version: %{modversion}
Release: 1
Source: ftp://ftp.cpan.org/pub/CPAN/%{modpath}

URL: http://www.cpan.org/
BuildArch: noarch
BuildRoot: %{_tmppath}/rpm-buildroot-%{name}-%{version}-%{release}
Prefix: %{_prefix}

Summary: MP3 file splitter / concatenator
License: Artistic or GPL
Group: Utilities/Text
Requires: %{modreq}
BuildPrereq: %{modreq}
Packager: jv@cpan.org
AutoReqProv: no
Provides: perl-Text-Filter perl(Text::Filter) perl(Text::Filter::Cooked)
Requires: perl perl(Carp) perl(Exporter) perl(IO::File) perl(Text::Filter) perl(strict) perl(vars)

%description
A plethora of tools exist that operate as filters: they get data from
a source, operate on this data, and write possibly modified data to a
destination. In the Unix world, these tools can be chained using a
technique called pipelining, where the output of one filter is
connected to the input of another filter. Some non-Unix worlds are
reported to have similar provisions.

To create Perl modules for filter functionality seems trivial at
first. Just open the input file, read and process it, and write output
to a destination file. But for really reusable modules this approach
is too simple. A reusable module should not read and write files
itself, but rely on the calling program to provide input as well as to
handle the output.

Text::Filter is a base class for modules that have in common that they
process text lines by reading from some source (usually a file),
manipulating the contents and writing something back to some
destination (usually some other file).

This module can be used 'as is', but its real power shows when used to
derive modules from it. See the documentation for extensive examples.

INSTALLATION HINTS:
 * If you have perl installed, but not from an rpm, you must
   specify "--nodeps" with the rpm command.

%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

%prep
%setup -q -n %{modname}-%{modversion}

%build
CFLAGS="$RPM_OPT_FLAGS" perl Makefile.PL \
	PREFIX=%{buildroot}%{_prefix} INSTALLDIRS=site
make
make test

%install
rm -rf %buildroot
make install_site

[ ! -x /usr/lib/rpm/brp-compress ] || /usr/lib/rpm/brp-compress

find %buildroot \( -name perllocal.pod -o -name .packlist \) -exec rm -vf {} \;
find %{buildroot}%{_prefix} -type f -print | sed 's|^%{buildroot}||' > rpm-files
[ -s rpm-files ] || exit 1

%clean
rm -rf %buildroot

%files -f rpm-files
%defattr(-,root,root)
%doc README INSTALL CHANGES examples
