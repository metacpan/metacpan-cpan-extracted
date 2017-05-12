use strict;
use warnings;

# Should be 28.
use Test::More tests => 28;

use XML::LibXSLT;
use XML::LibXML;

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

my $source = $parser->parse_string(<<'EOF');
<?xml version="1.0"?>
<foo/>
EOF

# TEST:$n=0;
my @style_docs;

# XML
# TEST:$n++;
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
# TEST:$n++;
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
# TEST:$n++;
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
# TEST:$n++;
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
# TEST:$n++;
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
# TEST:$n++;
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
# TEST:$n++;
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

# TEST:$num_style_docs=$n;
while (@style_docs) {
    my ($media_type, $style_str) = splice(@style_docs, 0, 2);

    my $style_doc = $parser->parse_string($style_str);
    # TEST*$num_style_docs
    ok($style_doc, ' TODO : Add test name');

    my $stylesheet = $xslt->parse_stylesheet($style_doc);
    # TEST*$num_style_docs
    ok($stylesheet, ' TODO : Add test name');

    my $results = $stylesheet->transform($source);
    # TEST*$num_style_docs
    ok($results, ' TODO : Add test name');

    # TEST*$num_style_docs
    is($stylesheet->media_type, $media_type, ' TODO : Add test name');
}
