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

sub handler_private {
    return join(",", "private", @_);
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
subtest "per-parser ext_ent_handler works" => sub {
    plan tests => 2;
    my $parser = XML::LibXML->new({
        expand_entities => 1,
        ext_ent_handler => \&handler_private,
    });
    my $doc;
    eval { $doc = $parser->parse_string($xml); };
    is($@ || '', '', "no error");
    is($doc->findvalue('//a'), "private,http:///invalid-url,//foo/bar/b",
        "private handler was called");
};

# TEST
subtest "without handler, parse fails" => sub {
    plan tests => 1;
    my $parser = XML::LibXML->new({ expand_entities => 1, no_network => 1 });
    eval { $parser->parse_string($xml); };
    ok($@, "error occurred without handler");
};

XML::LibXML::externalEntityLoader(\&handler_global);

# TEST
subtest "global handler overrides per-parser handler" => sub {
    plan tests => 2;
    my $parser = XML::LibXML->new({ expand_entities => 1 });
    my $doc;
    eval { $doc = $parser->parse_string($xml); };
    is($@ || '', '', "no error");
    is($doc->findvalue('//a'), "global,http:///invalid-url,//foo/bar/b",
        "global handler takes precedence");
};

XML::LibXML::externalEntityLoader(undef);

# TEST
subtest "after clearing global, per-parser handler works again" => sub {
    plan tests => 2;
    my $parser = XML::LibXML->new({
        expand_entities => 1,
        ext_ent_handler => \&handler_private,
    });
    my $doc;
    eval { $doc = $parser->parse_string($xml); };
    is($@ || '', '', "no error");
    is($doc->findvalue('//a'), "private,http:///invalid-url,//foo/bar/b",
        "private handler works after global cleared");
};

# TEST
subtest "without any handler, parse fails again" => sub {
    plan tests => 1;
    my $parser = XML::LibXML->new({ expand_entities => 1, no_network => 1 });
    eval { $parser->parse_string($xml); };
    ok($@, "error occurred without handler");
};
