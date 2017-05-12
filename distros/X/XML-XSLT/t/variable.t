#!/usr/bin/perl -w
# Test for correct operation of variables
# $Id: variable.t,v 1.1 2004/02/16 10:29:20 gellyfish Exp $


use Test::More tests => 14;
use strict;

use vars qw($DEBUGGING);

$DEBUGGING = 0;

use_ok('XML::XSLT');

# Test literal value in select

my $stylesheet =<<'EOS';
<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xsl:version="1.0">
  <xsl:output method="text" />
  <xsl:template match="/">
     <xsl:variable name="Test" select="'*This is a test*'" />
     <xsl:value-of select="$Test" />
  </xsl:template>
</xsl:transform>
EOS

my $xml =<<EOX;
<?xml version="1.0"?>
<foo />
EOX

my $correct = '*This is a test*';
my $parser;

eval 
{
   $parser = XML::XSLT->new($stylesheet, debug => $DEBUGGING );
   die unless $parser;
};

warn $@ if $DEBUGGING;
ok(!$@,"new from literal stylesheet");

eval
{
   $parser->transform(\$xml);
};

warn $@ if $DEBUGGING;
ok(! $@, "transform" );

my $outstr;
                                                                                
eval
{
  $outstr = $parser->toString();
  die unless $outstr;
};
                                                                                
warn $outstr if $DEBUGGING;
warn $@ if $DEBUGGING;
                                                                                
ok(!$@,"toString works");
                                                                                
                                                                                
ok($outstr eq $correct,"Output meets expectations - with toString");

$stylesheet =<<'EOS';
<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xsl:version="1.0">
  <xsl:output method="text" />
  <xsl:template match="/">
     <xsl:variable name="Test">*This is a test*</xsl:variable>
     <xsl:value-of select="$Test" />
  </xsl:template>
</xsl:transform>
EOS

eval
{
    $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);
    die unless $parser;
};

ok(!$@, 'Can parse template value as variable');

eval
{
   $parser->transform(\$xml);
};

ok(!$@, 'transform');

eval
{
   $outstr = $parser->toString();
   die unless $outstr;
};

ok(!$@,'got some output');

ok($outstr eq $correct,'Got expected output');

$stylesheet =<<'EOS';
<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xsl:version="1.0">
  <xsl:output method="text" />
  <xsl:template match="/">
     <xsl:variable name="Test" select="foo/@attr" />
     <xsl:value-of select="$Test" />
  </xsl:template>
</xsl:transform>
EOS

$xml =<<EOX;
<?xml version="1.0"?>
<foo attr="*This is a test*" />
EOX

eval
{
    $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);
    die unless $parser;
};

ok(!$@, 'Can parse template');

eval
{
   $parser->transform(\$xml);
};

ok(!$@, 'transform');

eval
{
   $outstr = $parser->toString();
   die unless $outstr;
};

ok(!$@,'got some output');

ok($outstr eq $correct,'Got expected output');

eval
{
    $stylesheet =<<'EOS';
<?xml version='1.0' encoding='utf-8'?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
<xsl:param name='param1'/>
<xsl:param name='param2'/>
<xsl:template match='test'><p>param1 = <xsl:value-of select="$param1"/></p><p>param2 = <xsl:value-of select="$param2"/></p>
</xsl:template>
</xsl:stylesheet>
EOS

   $xml =<<EOX;
<?xml version='1.0' encoding='utf-8'?>
<doc><test comment='testing...'/></doc>
EOX

   $parser = XML::XSLT->new($stylesheet, debug => $DEBUGGING,
                            variables => { param1 => "One", param2 => "Two" });

   $parser->transform(\$xml);

   $outstr = $parser->toString();

   $correct = '<p>param1 = One</p><p>param2 = Two</p>';
   die "$outstr ne $correct" unless $outstr eq $correct;
};

ok(!$@,"external variables work as expected");
