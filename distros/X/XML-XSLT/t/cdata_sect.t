# Test that cdata-section elements work 
# $Id: cdata_sect.t,v 1.4 2002/01/14 09:40:23 gellyfish Exp $

use Test::More tests => 7;

use strict;
use vars qw($DEBUGGING);

$DEBUGGING = 0;

use_ok('XML::XSLT');

# First example

my $stylesheet =<<EOS;
<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version='1.0'>

<xsl:output cdata-section-elements="example"/>

<xsl:template match="/">
<example>&lt;foo></example>
</xsl:template>
</xsl:stylesheet>
EOS

my $xml = '<doc />';

# this is not the same as that in the spec because of white space issues

my $expected =<<EOE;
<?xml version="1.0" encoding="UTF-8"?>
<example><![CDATA[<foo>]]></example>
EOE

chomp($expected);

my $parser;

eval
{
   $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);
   die unless $parser;
};

warn $@ if $DEBUGGING;

ok(!$@,'Can parse example stylesheet');

my $outstr;
eval
{
   $outstr = $parser->serve(\$xml,http_headers => 0);
   die "no output" unless $outstr;
};

warn $@ if $DEBUGGING;

ok(!$@,'serve produced output');

warn $outstr if $DEBUGGING;

ok($outstr eq $expected,'Matches output');

$parser->dispose();

# The data example - test 'Literal result as stylesheet'

$stylesheet =<<'EOS';
<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version='1.0'>

<xsl:output cdata-section-elements="example"/>

<xsl:template match="/">
<example><![CDATA[<foo>]]></example>
</xsl:template>
</xsl:stylesheet>
EOS

$expected =<<EOE;
<?xml version="1.0" encoding="UTF-8"?>
<example><![CDATA[<foo>]]></example>
EOE

chomp ($expected);

eval
{
   $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);
   die unless $parser;
};

ok(!$@,'Wahay it can parse literal result');

eval
{
   $outstr = $parser->serve(\$xml,http_headers => 0);
   die unless $outstr;
};

ok(!$@,'serve at least did something');


ok( $outstr eq $expected,'Preserves CDATA');

print $outstr if $DEBUGGING;
