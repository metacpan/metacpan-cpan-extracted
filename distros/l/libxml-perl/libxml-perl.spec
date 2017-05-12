Summary: Collection of Perl modules for working with XML
Name: libxml-perl
Version: @VERSION@
Release: 1
Source: http://www.perl.com/CPAN/modules/by-module/XML/libxml-perl-@VERSION@.tar.gz
Copyright: Artistic or GPL
Group: Applications/Publishing/XML
URL: http://www.perl.com/
Packager: ken@bitsko.slc.ut.us (Ken MacLeod)
BuildRoot: /tmp/libxml-perl

#
# $Id: libxml-perl.spec,v 1.4 1999/08/16 16:10:43 kmacleod Exp $
#

%description
libxml-perl is a collection of Perl modules for working with XML.

%prep
%setup

perl Makefile.PL INSTALLDIRS=perl

%build

make

%install

make PREFIX="${RPM_ROOT_DIR}/usr" pure_install

DOCDIR="${RPM_ROOT_DIR}/usr/doc/libxml-perl-@VERSION@-1"
mkdir -p "$DOCDIR/examples"
for ii in PerlSAX.pod UsingPerlSAX.pod interface-style.pod modules.xml; do
  cp doc/$ii "$DOCDIR/$ii"
  chmod 644 "$DOCDIR/$ii"
done
for ii in README Changes examples/*; do
  cp $ii "$DOCDIR/$ii"
  chmod 644 "$DOCDIR/$ii"
done

%files

/usr/doc/libxml-perl-@VERSION@-1

/usr/lib/perl5/Data/Grove.pm
/usr/lib/perl5/Data/Grove/Parent.pm
/usr/lib/perl5/Data/Grove/Visitor.pm
/usr/lib/perl5/XML/ESISParser.pm
/usr/lib/perl5/XML/Handler/CanonXMLWriter.pm
/usr/lib/perl5/XML/Handler/Sample.pm
/usr/lib/perl5/XML/Handler/Subs.pm
/usr/lib/perl5/XML/Handler/XMLWriter.pm
/usr/lib/perl5/XML/SAX2Perl.pm
/usr/lib/perl5/XML/Perl2SAX.pm
/usr/lib/perl5/XML/Parser/PerlSAX.pm
/usr/lib/perl5/XML/PatAct/ActionTempl.pm
/usr/lib/perl5/XML/PatAct/Amsterdam.pm
/usr/lib/perl5/XML/PatAct/MatchName.pm
/usr/lib/perl5/XML/PatAct/PatternTempl.pm
/usr/lib/perl5/XML/PatAct/ToObjects.pm
/usr/lib/perl5/man/man3/Data::Grove.3
/usr/lib/perl5/man/man3/Data::Grove::Parent.3
/usr/lib/perl5/man/man3/Data::Grove::Visitor.3
/usr/lib/perl5/man/man3/XML::Handler::CanonXMLWriter.3
/usr/lib/perl5/man/man3/XML::Handler::Sample.3
/usr/lib/perl5/man/man3/XML::Handler::Subs.3
/usr/lib/perl5/man/man3/XML::Handler::XMLWriter.3
/usr/lib/perl5/man/man3/XML::ESISParser.3
/usr/lib/perl5/man/man3/XML::SAX2Perl.3
/usr/lib/perl5/man/man3/XML::Perl2SAX.3
/usr/lib/perl5/man/man3/XML::Parser::PerlSAX.3
/usr/lib/perl5/man/man3/XML::PatAct::ActionTempl.3
/usr/lib/perl5/man/man3/XML::PatAct::Amsterdam.3
/usr/lib/perl5/man/man3/XML::PatAct::MatchName.3
/usr/lib/perl5/man/man3/XML::PatAct::PatternTempl.3
/usr/lib/perl5/man/man3/XML::PatAct::ToObjects.3
