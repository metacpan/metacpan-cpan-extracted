use strict;
use warnings;

# Should be 28.
use Test::More tests => 28;
use XML::LibXSLT;
use XML::LibXML 1.59;

my $parser = XML::LibXML->new();
# parser
# TEST
ok ($parser, 'Parser was initted.');

my $doc = $parser->parse_string(<<'EOT');
<xml>random contents</xml>
EOT

# doc
# TEST
ok ($doc, 'Doc was initted.');

my $xslt = XML::LibXSLT->new();
# xslt
# TEST
ok ($xslt, 'xslt was initted.');

my $stylsheetstring = <<'EOT';
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns="http://www.w3.org/1999/xhtml">

<xsl:template match="/">
<html>
<head><title>Know Your Dromedaries</title></head>
<body>
  <h1><xsl:apply-templates/></h1>
  <p>foo: <xsl:apply-templates select="document('foo.xml')/*" /></p>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
EOT

my $icb = XML::LibXML::InputCallback->new();
# TEST
ok ($icb, 'icb was initted.');

# registering callbacks
$icb->register_callbacks( [ \&match_cb, \&open_cb,
                            \&read_cb, \&close_cb ] );

$xslt->input_callbacks($icb);

my $stylesheet = $xslt->parse_stylesheet($parser->parse_string($stylsheetstring));
# stylesheet
# TEST
ok ($stylesheet, 'stylesheet is OK.');

#$stylesheet->input_callbacks($icb);

# warn "transforming\n";
my $results = $stylesheet->transform($doc);
# results
# TEST
ok ($results, 'results is OK.');

my $output = $stylesheet->output_string($results);
# warn "output: $output\n";
# TEST
ok ($output, 'output is OK.');

# test a dying close callback
# callbacks can only be registered as a callback group
$stylesheet->match_callback( \&match_cb );
$stylesheet->open_callback( \&dying_open_cb );
$stylesheet->read_callback( \&read_cb );
$stylesheet->close_callback( \&close_cb );

# check if transform throws an exception
# dying callback test
eval {
    $stylesheet->transform($doc);
};
{
    my $E = $@;
    # TEST
    ok ($E, "Threw: $E");
}

#
# test the old global|local-variables-using callback interface
#

$xslt = undef;
$stylesheet = undef;
$xslt = XML::LibXSLT->new();
$stylesheet = $xslt->parse_stylesheet($parser->parse_string($stylsheetstring));

{
    # setting callbacks
    local $XML::LibXML::match_cb = \&match_cb;
    local $XML::LibXML::open_cb = \&open_cb;
    local $XML::LibXML::close_cb = \&close_cb;
    local $XML::LibXML::read_cb = \&read_cb;

    # warn "transform!\n";
    $results = $stylesheet->transform($doc);

    # results
    # TEST
    ok ($results, 'results is OK - 2.');

    $output = $stylesheet->output_string($results);

    # warn "output: $output\n";
    # output
    # TEST
    ok ($output, 'output is OK - 2.');

    $XML::LibXML::open_cb = \&dying_open_cb;

    # check if the transform throws an exception
    eval {
        $stylesheet->transform($doc);
    };
    {
        my $E = $@;
        # TEST
        ok ($E, "Transform Threw: $E");
    }
}

#
# test callbacks for parse_stylesheet()
#

$xslt = undef;
$stylesheet = undef;
$icb = undef;

$xslt = XML::LibXSLT->new();
$icb = XML::LibXML::InputCallback->new();

# registering callbacks
$icb->register_callbacks( [ \&match_cb, \&stylesheet_open_cb,
                            \&read_cb, \&close_cb ] );

$xslt->input_callbacks($icb);

$stylsheetstring = <<'EOT';
<xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns="http://www.w3.org/1999/xhtml">

<xsl:import href="foo.xml"/>

<xsl:template match="/">
<html>
<head><title>Know Your Dromedaries</title></head>
<body>
  <h1><xsl:apply-templates/></h1>
  <p>Dahut!</p>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
EOT

$stylesheet = $xslt->parse_stylesheet($parser->parse_string($stylsheetstring));
# stylesheet
# TEST
ok ($stylesheet, 'stylesheet is OK - 2.');

#
# Test not matching callback
# This also verifies that all the previous callbacks were unregistered.
#

$xslt = undef;
$stylesheet = undef;
$icb = undef;

$xslt = XML::LibXSLT->new();
$icb = XML::LibXML::InputCallback->new();

# registering callbacks
$icb->register_callbacks( [ \&match_cb, \&stylesheet_open_cb,
                            \&read_cb, \&close_cb ] );

$xslt->input_callbacks($icb);

my $no_match_count = 0;

$stylsheetstring = <<'EOT';
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <result>
            <xsl:apply-templates select="document('not-found.xml')/*"/>
        </result>
    </xsl:template>
</xsl:stylesheet>
EOT

$stylesheet = $xslt->parse_stylesheet($parser->parse_string($stylsheetstring));
# stylesheet
# TEST
ok ($stylesheet, 'stylesheet is OK - 3.');

$results = $stylesheet->transform($doc);
# results
# TEST
ok ($results, 'results is OK - 3.');

# no_match_count
# TEST
is ($no_match_count, 1, 'match_cb called once if no match');

#
# input callback functions
#

sub match_cb {
    my $uri = shift;
    # match_cb
    if ($uri eq "foo.xml") {
        # TEST*5
        ok(1, 'URI is OK in match_cb.');
        return 1;
    }
    if ($uri eq "not-found.xml") {
        ++$no_match_count;
        return 0;
    }
    return 0;
}

sub open_cb {
    my $uri = shift;
    # TEST*2
    is ($uri, 'foo.xml', 'URI is OK in open_cb.');
    my $str ="<foo>Text here</foo>";
    return \$str;
}

sub dying_open_cb {
    my $uri = shift;
    # dying_open_cb: $uri
    # TEST*2
    is ($uri, 'foo.xml', 'dying_open_cb');
    die "Test a die from open_cb";
}

sub stylesheet_open_cb {
    my $uri = shift;
    # TEST
    is ($uri, 'foo.xml', 'stylesheet_open_cb uri compare.');
    my $str = '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"/>';
    return \$str;
}

sub close_cb {
    # warn("close\n");
    # TEST*3
    ok(1, 'close_cb()');
}

sub read_cb {
#    warn("read\n");
    return substr(${$_[0]}, 0, $_[1], "");
}
