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
    plan tests => 5;
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
subtest "initial parse fails without handler" => sub {
    plan tests => 2;
    my $parser = XML::LibXML->new({ expand_entities => 1, no_network => 1 });
    my $doc;
    eval { $doc = $parser->parse_string($xml); };
    ok($@, "error occurred");
    is($doc, undef, "doc is undef");
};

# TEST
is(XML::LibXML::externalEntityLoader(\&handler_global), undef,
    "previous handler is undef");

# TEST
subtest "parse with global handler works" => sub {
    plan tests => 2;
    my $parser = XML::LibXML->new({ expand_entities => 1 });
    my $doc;
    eval { $doc = $parser->parse_string($xml); };
    is($@ || '', '', "no error");
    is($doc->findvalue('//a'), "global,http:///invalid-url,//foo/bar/b",
        "global handler was called");
};

# TEST
is(ref(XML::LibXML::externalEntityLoader(undef)), "CODE",
    "previous handler returned as code ref");

# TEST
subtest "after clearing, no_network is respected again" => sub {
    plan tests => 2;
    my $parser = XML::LibXML->new({ expand_entities => 1, no_network => 1 });
    my $doc;
    eval { $doc = $parser->parse_string($xml); };
    ok($@, "error occurred");
    is($doc, undef, "doc is undef");
};
