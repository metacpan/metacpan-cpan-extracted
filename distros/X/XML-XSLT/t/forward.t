# Test forward compatibility
# $Id: forward.t,v 1.2 2002/01/09 09:17:40 gellyfish Exp $

use strict;

use vars qw($DEBUGGING);

$DEBUGGING = 0;

use Test::More tests => 8;

use_ok('XML::XSLT');

my $stylesheet =<<EOS;
<?xml version="1.0" ?>
<xsl:stylesheet version="17.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="system-property('xsl:version') >= 17.0">
         <xsl:some-funky-17.0-feature />
      </xsl:when>
      <xsl:otherwise>
        <html>
        <head>
          <title>XSLT 17.0 required</title>
        </head>
        <body>
          <p>Sorry, this stylesheet requires XSLT 17.0.</p>
        </body>
        </html>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
EOS

my $parser;

eval
{
   $parser = XML::XSLT->new(\$stylesheet,debug => $DEBUGGING);
   die unless $parser;
};

warn $@ if $DEBUGGING;

ok(! $@,'Forward compatibility as per 1.1 Working Draft');

my $xml = '<doc>Test data</doc>';

my $outstr;

eval
{
   $parser->transform($xml);
   $outstr = $parser->toString();
   die unless $outstr;
};

warn $@ if $DEBUGGING;

print $outstr if $DEBUGGING;

ok(! $@, 'Check it can process this');

my $wanted =<<EOW;
<html><head><title>XSLT 17.0 required</title></head><body><p>Sorry, this stylesheet requires XSLT 17.0.</p></body></html>
EOW

chomp($wanted);

ok($outstr eq $wanted, 'Check it makes the right output');

$stylesheet =<<EOS;
<?xml version="1.0" ?>
<xsl:stylesheet version="18.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">   
  <xsl:some-18.0-feature />
  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="system-property('xsl:version') &lt; 17.0">
        <xsl:message terminate="yes">
          <xsl:text>Sorry, this stylesheet requires XSLT 17.0.</xsl:text>
        </xsl:message>
      </xsl:when>
      <xsl:otherwise>
         <xsl:apply-templates />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
EOS

eval
{
   $parser->dispose();
};

ok(!$@, 'dispose');

eval
{
   $parser = XML::XSLT->new( \$stylesheet,debug => $DEBUGGING) || die;
};

ok(! $@, 'Another forward compat test');

eval
{
   $parser->transform($xml);
   $outstr = $parser->toString();
   die unless $outstr;
};

print $outstr if $DEBUGGING;

ok(! $@, 'Transform this');

$wanted = 'Test data';

chomp($wanted);

ok($outstr eq $wanted, 'Check it makes the right output');
