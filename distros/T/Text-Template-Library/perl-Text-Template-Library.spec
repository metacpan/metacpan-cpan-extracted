Name:         perl-Text-Template-Library
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version}
Autoreqprov:  on
Summary:      Text::Template::Library
Version:      0.03
Release:      1
Source:       Text-Template-Library-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
Text::Template::Library


Authors:
--------
    Torsten Förtsch <torsten.foertsch@gmx.net>

%prep
%setup -n Text-Template-Library-%{version}
# ---------------------------------------------------------------------------

%build
perl Makefile.PL
make && make test
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT install_vendor
find $RPM_BUILD_ROOT%{_mandir}/man* -type f -print0 |
  xargs -0i^ %{_gzipbin} -9 ^ || true
%perl_process_packlist

%files
%defattr(-, root, root)
%{perl_vendorlib}/Text
%{perl_vendorarch}/auto/Text
%doc %{_mandir}/man3/Text::Template::Library.3pm.gz
%doc %{_mandir}/man3/Text::Template::Base.3pm.gz
/var/adm/perl-modules/perl-Text-Template-Library
%doc MANIFEST README
