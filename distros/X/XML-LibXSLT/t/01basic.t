use strict;
use warnings;

use vars qw($loaded);

use Test::More tests => 4;

use XML::LibXSLT;

# TEST
ok(1, ' TODO : Add test name');

my $p = XML::LibXSLT->new();

# TEST
ok($p, ' TODO : Add test name');

# TEST
is(XML::LibXSLT::LIBXSLT_VERSION(), XML::LibXSLT::LIBXSLT_RUNTIME_VERSION(), 'LIBXSLT_VERSION is the same as the runtime version.');

# TEST
is(XML::LibXML::LIBXML_VERSION(), XML::LibXML::LIBXML_RUNTIME_VERSION(), 'LibXML version is the same as its run time version.');

warn "\n\nCompiled against:    ",
       "libxslt ",XML::LibXSLT::LIBXSLT_VERSION(),
       ", libxml2 ",XML::LibXML::LIBXML_VERSION(),
       "\nRunning:             ",
       "libxslt ",XML::LibXSLT::LIBXSLT_RUNTIME_VERSION(),
       ", libxml2 ",XML::LibXML::LIBXML_RUNTIME_VERSION(),
       "\nCompiled with EXSLT: ", (XML::LibXSLT::HAVE_EXSLT() ? 'yes' : 'no'),
     "\n\n";

if (XML::LibXSLT::LIBXSLT_VERSION() != XML::LibXSLT::LIBXSLT_RUNTIME_VERSION()
    or
    XML::LibXML::LIBXML_VERSION() != XML::LibXML::LIBXML_RUNTIME_VERSION()
    ) {
   warn "DO NOT REPORT THIS FAILURE: Your setup of library paths is incorrect!\n\n";
}
