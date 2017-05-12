# $Id: xsl_cond.t,v 1.3 2001/12/17 11:32:09 gellyfish Exp $
# check test attributes && the interface

use Test::More tests => 25;
use strict;
use vars qw($DEBUGGING);

$DEBUGGING = 0;

use_ok('XML::XSLT');

# element tests
eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title='foo'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title='foo'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>foo</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node string eq");

eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title != 'foo'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title != 'foo'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>bar</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

ok(!$@,"text node string ne");

eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title &lt; 'b'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title &lt; 'b'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>a</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node string lt");

eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title > 'b'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title > 'b'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>c</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node string gt");

eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title >= 'b'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title >= 'b'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>c</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node string ge");

eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title &lt;= 'b'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title &lt;= 'b'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>b</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node string le");

eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title = 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title = 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>42</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

ok(!$@,"text node numeric eq");


eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title != 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title != 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>43</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node numeric ne");

eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title &lt; 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title &lt; 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>41</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node numeric lt");

eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title > 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title > 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>43</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node numeric gt");


eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title >= 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title >= 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>43</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node numeric ge");

eval 
{
   my $parser =  XML::XSLT->new (<<EOS, debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="title &lt;= 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="title &lt;= 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p><title>41</title>some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"text node numeric le");

# attribute tests

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title='foo'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title='foo'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="foo">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute string eq");

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title != 'foo'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title != 'foo'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="bar">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

ok(!$@,"attribute string ne");

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title &lt; 'b'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title &lt; 'b'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="a">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute string lt");

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title > 'b'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title > 'b'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="c">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute string gt");

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title >= 'b'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title >= 'b'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="c">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute string ge");

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title &lt;= 'b'">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title &lt;= 'b'">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="b">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute string le");

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title = 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title = 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="42">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

ok(!$@,"attribute numeric eq");


eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title != 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title != 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="43">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute numeric ne");

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title &lt; 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title &lt; 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="41">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute numeric lt");

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title > 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title > 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="43">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute numeric gt");


eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title >= 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title >= 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="42">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute numeric ge");

eval 
{
   my $parser =  XML::XSLT->new (<<'EOS', debug => $DEBUGGING);
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="doc"><doc><xsl:apply-templates/></doc></xsl:template>
<xsl:template match="p"><xsl:choose>
 <xsl:when test="@title &lt;= 42">o</xsl:when>
 <xsl:otherwise>not ok</xsl:otherwise>
</xsl:choose><xsl:if test="@title &lt;= 42">k</xsl:if></xsl:template>
</xsl:stylesheet>
EOS

   $parser->transform(\<<EOX);
<?xml version="1.0"?><doc><p title="41">some random text</p></doc>
EOX

   my $outstr =  $parser->toString();

   warn $outstr if $DEBUGGING;


   my $correct = '<doc>ok</doc>';

   $parser->dispose();

   die "$outstr ne $correct\n" unless $outstr eq $correct;
};

warn $@ if $DEBUGGING;
ok(!$@,"attribute numeric le");

