use Test;
BEGIN { plan tests => 29 }

use XML::GDOME::XSLT;
use XML::GDOME;
ok(1);

my $parser = XML::GDOME->new();
my $xslt = XML::GDOME::XSLT->new();

my $source = $parser->parse_string(<<'EOF');
<?xml version="1.0"?>
<foo/>
EOF

my @style_docs;

# XML
push @style_docs, "text/xml", <<'EOF';
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="xml"/>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# HTML
push @style_docs, "text/html", <<'EOF';
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="html"/>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# TEXT
push @style_docs, "text/plain", <<'EOF';
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="text"/>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# Default XML
push @style_docs, "text/xml", <<'EOF';
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# Default HTML (broken for now!)
push @style_docs, "text/html", <<'EOF';
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:template match="/">
<html>
  <body>
    <xsl:apply-templates/>
  </body>
</html>
</xsl:template>

<xsl:template match="*|@*">
  <xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# Text, other
push @style_docs, "text/rtf", <<'EOF';
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output method="text" media-type="text/rtf"/>

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

# XML, other
push @style_docs, "text/vnd.wap.wml", <<'EOF';
<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
>

<xsl:output media-type="text/vnd.wap.wml" />

<xsl:template match="*|@*">
<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
EOF

while (@style_docs) {
    my ($media_type, $style_str) = splice(@style_docs, 0, 2);
    
    my $style_doc = $parser->parse_string($style_str);
    ok($style_doc);
    
    my $stylesheet = $xslt->parse_stylesheet($style_doc);
    ok($stylesheet);
    
    my $results = $stylesheet->transform($source);
    ok($results);
    
    ok($stylesheet->media_type, $media_type);
}
