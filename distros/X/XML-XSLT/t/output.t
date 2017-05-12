# Test for 'output'  (which is hopefully fixed)
# $Id: output.t,v 1.3 2002/01/09 09:17:40 gellyfish Exp $

use Test::More tests => 7;
use strict;

use vars qw($DEBUGGING);

$DEBUGGING = 0;

use_ok('XML::XSLT');

my $stylesheet = <<EOS;
<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns="http://www.w3.org/TR/xhtml1/strict"
               version="1.0">

  <xsl:output method="xml"
       encoding="ISO-8859-1"
       doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
       indent="yes"/>

<xsl:template match="/">
<foo><xsl:apply-templates /></foo>
</xsl:template>
</xsl:transform>
EOS

my $xml =<<EOX;
<?xml version="1.0"?>
<foo>This is a test</foo>
EOX


my $parser;

eval
{
  $parser = XML::XSLT->new($stylesheet, debug => $DEBUGGING);
  die unless $parser;
};
warn $@ if $DEBUGGING;
ok (!$@,"new from literal stylesheet");

eval
{
   $parser->transform(\$xml);
};

warn $@ if $DEBUGGING;

ok(! $@, "transform");

my $correct = "<foo>This is a test</foo>";

my $outstr;

warn $outstr if $DEBUGGING;
eval
{
  $outstr = $parser->toString();
  die unless $outstr;
};

warn $@ if $DEBUGGING;

ok(!$@,"toString works");


ok($outstr eq $correct,"Output meets expectations - with toString");

$correct =<<EOC;
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE foo PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "">
<foo>This is a test</foo>
EOC

chomp($correct);

eval
{
   $outstr = $parser->serve(\$xml,http_headers => 0);
   die unless $outstr;
};


warn $outstr if $DEBUGGING;

ok(!$@,"serve(), works");

ok($outstr eq $correct,"Output meets expectations with declarations");

