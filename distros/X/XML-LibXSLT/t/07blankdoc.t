use strict;
use warnings;

# Should be 5.
use Test::More tests => 5;
use XML::LibXSLT;

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

# TEST
ok($parser, 'parser was initted.');
# TEST
ok($xslt, 'xslt object was initted.');

local $XML::LibXML::match_cb = \&match_cb;
local $XML::LibXML::open_cb = \&open_cb;
local $XML::LibXML::close_cb = \&close_cb;
local $XML::LibXML::read_cb = \&read_cb;

my $source = $parser->parse_string(<<'EOT','/foo');
<?xml version="1.0" encoding="ISO-8859-1"?>
<document></document>
EOT

my $foodoc = <<'EOT';
<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:data="data.uri" version="1.0">
<xsl:output encoding="ISO-8859-1" method="text"/>

<data:type>typed data in stylesheet</data:type>

<xsl:template match="/*">

Data: <xsl:value-of select="document('')/xsl:stylesheet/data:type"/><xsl:text>
</xsl:text>

</xsl:template>

</xsl:stylesheet>
EOT

my $style = $parser->parse_string($foodoc,'foo');

# TEST
ok($style, '$style is true');

my $stylesheet = $xslt->parse_stylesheet($style);
# my $stylesheet = $xslt->parse_stylesheet_file("example/document.xsl");

my $results = $stylesheet->transform($source);
# TEST
ok ($results, 'Results are true.');
# TEST
like ($results->toString, qr/typed data in stylesheet/,
    'found "typed data in stylesheet"');

###############################################################
# Callbacks - this is needed because with document('') now,
# libxslt expects to re-get the entire file and re-parse it,
# rather than its old behaviour, which was to use the internal
# DOM. So we have to use callbacks to be able to return the
# original file. We also need to make sure that the call
# to $parser->parse_string($foodoc, 'foo') gets a URI (second
# param), otherwise it doesn't know what to fetch.

sub match_cb {
    my $uri = shift;
    if ($uri eq 'foo') {
        return 1;
    }
    return 0;
}

sub open_cb {
    my $uri = shift;
    return \$foodoc;
}

sub close_cb {
}

sub read_cb {
    return substr(${$_[0]}, 0, $_[1], "");
}

