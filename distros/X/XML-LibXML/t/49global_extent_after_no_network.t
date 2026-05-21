use strict;
use warnings;

use Test::More;
use XML::LibXML;

if (XML::LibXML::LIBXML_VERSION() < 20627)
{
    plan skip_all => "skipping for libxml2 < 2.6.27";
}
else
{
    plan tests => 2;
}

sub handler_global {
    return join(",", "global", @_);
}

my $xml = <<'EOF';
<?xml version="1.0"?>
<!DOCTYPE foo [
<!ENTITY a PUBLIC "//foo/bar/b" "http:///invalid-url">
]>
<root>
  <a>&a;</a>
</root>
EOF

# TEST
subtest "initial parse with no_network fails" => sub {
    plan tests => 2;
    my $parser = XML::LibXML->new({ expand_entities => 1, no_network => 1 });
    my $doc;
    eval { $doc = $parser->parse_string($xml); };
    ok($@, "error occurred when network disabled");
    is($doc, undef, "doc is undef");
};

XML::LibXML::externalEntityLoader(\&handler_global);

# TEST
subtest "global handler takes effect after prior no_network parse" => sub {
    plan tests => 2;
    my $parser = XML::LibXML->new({ expand_entities => 1 });
    my $doc;
    eval { $doc = $parser->parse_string($xml); };
    is($@ || '', '', "no error");
    is($doc->findvalue('//a'), "global,http:///invalid-url,//foo/bar/b",
        "global handler was called");
};
