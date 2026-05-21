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
    plan tests => 4;
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
subtest "repeated set does not leak (replaces handler)" => sub {
    plan tests => 4;
    my $first  = sub { return "first" };
    my $second = sub { return "second" };

    my $old1 = XML::LibXML::externalEntityLoader($first);
    is($old1, undef, "first set returns undef");

    my $old2 = XML::LibXML::externalEntityLoader($second);
    is(ref($old2), "CODE", "second set returns previous handler");

    my $parser = XML::LibXML->new({ expand_entities => 1 });
    my $doc = $parser->parse_string($xml);
    is($doc->findvalue('//a'), "second", "second handler is active");

    XML::LibXML::externalEntityLoader(undef);
    is(ref(XML::LibXML::externalEntityLoader(undef)), "", "after double-clear, returns undef");
};

# TEST
subtest "set -> clear -> set cycle works" => sub {
    plan tests => 3;
    my $handler = sub { return "cycled" };

    XML::LibXML::externalEntityLoader($handler);
    XML::LibXML::externalEntityLoader(undef);
    XML::LibXML::externalEntityLoader($handler);

    my $parser = XML::LibXML->new({ expand_entities => 1 });
    my $doc = $parser->parse_string($xml);
    is($doc->findvalue('//a'), "cycled", "handler works after cycle");

    my $prev = XML::LibXML::externalEntityLoader(undef);
    is(ref($prev), "CODE", "returned previous handler");

    my $parser2 = XML::LibXML->new({ expand_entities => 1, no_network => 1 });
    eval { $parser2->parse_string($xml) };
    ok($@, "cleared handler - parse fails");
};

# TEST
subtest "global handler set -> parse with ext_ent_handler -> clear global -> parse with ext_ent_handler" => sub {
    plan tests => 3;
    my $global_h = sub { return "global" };
    my $private_h = sub { return "private" };

    XML::LibXML::externalEntityLoader($global_h);

    my $p1 = XML::LibXML->new({
        expand_entities => 1,
        ext_ent_handler => $private_h,
    });
    my $doc1 = $p1->parse_string($xml);
    is($doc1->findvalue('//a'), "global",
        "global overrides per-parser while active");

    XML::LibXML::externalEntityLoader(undef);

    my $p2 = XML::LibXML->new({
        expand_entities => 1,
        ext_ent_handler => $private_h,
    });
    my $doc2 = $p2->parse_string($xml);
    is($doc2->findvalue('//a'), "private",
        "per-parser handler works after global cleared");

    my $p3 = XML::LibXML->new({ expand_entities => 1, no_network => 1 });
    eval { $p3->parse_string($xml) };
    ok($@, "without any handler, parse fails");
};

# TEST
subtest "clearing when nothing is set is harmless" => sub {
    plan tests => 2;
    my $ret = XML::LibXML::externalEntityLoader(undef);
    is($ret, undef, "clearing unset returns undef");

    my $parser = XML::LibXML->new({ expand_entities => 1, no_network => 1 });
    eval { $parser->parse_string($xml) };
    ok($@, "parse still fails as expected");
};
