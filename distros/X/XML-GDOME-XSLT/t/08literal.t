use Test;
BEGIN { plan tests => 5 }
use XML::GDOME::XSLT;

my $parser = XML::GDOME->new();
my $xslt = XML::GDOME::XSLT->new();
ok($parser); ok($xslt);

my $source = $parser->parse_string(<<'EOT');
<?xml version="1.0" encoding="ISO-8859-1"?>
<document></document>
EOT

my $style = $parser->parse_string(<<'EOT');
<html
    xsl:version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>
<head>
</head>
</html>
EOT

ok($style);
my $stylesheet = $xslt->parse_stylesheet($style);

my $results = $stylesheet->transform($source);
ok($results);

ok($stylesheet->media_type, 'text/html');
