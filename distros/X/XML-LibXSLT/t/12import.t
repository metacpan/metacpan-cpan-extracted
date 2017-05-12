# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 6;

use vars (qw($loaded));

END {
    # TEST
    ok($loaded, 'Everything was properly loaded.');
}

use XML::LibXSLT;

$loaded = 1;

# TEST
ok(1, 'Running');
my $x = XML::LibXML->new() ;
# TEST
ok($x, 'XML::LibXML->new works.') ;
my $p = XML::LibXSLT->new();
# TEST
ok($p, 'XML::LibXSLT->new owrks.');
my $xsl = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 version="1.0"> <xsl:import href="example/2.xsl" />
 <xsl:output method="html" />
</xsl:stylesheet>
EOF

my $xsld = $x->parse_string($xsl) ;
# TEST
ok($xsld, 'parse_string returned a true value.') ;
my $tr = $p->parse_stylesheet($xsld) ;
# TEST
ok($tr, 'parse_stylesheet returned a true value.') ;
