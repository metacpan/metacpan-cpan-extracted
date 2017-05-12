use Test;
use XML::Filter::SAX2toSAX1;
BEGIN {
    eval {
        require XML::SAX::ParserFactory;
        require XML::Handler::YAWriter;
    };
    if ($@) {
        plan tests => 0;
        exit(0);
    }
    plan tests => 5;
}

my $sax = XML::SAX::ParserFactory->parser(
    Handler => XML::Filter::SAX2toSAX1->new(
        Handler => XML::Handler::YAWriter->new( AsString => 1 )
    )
);

ok($sax);

print "Parser: $sax\n";

my $scalar = $sax->parse_string(q(<ns:foo xmlns:ns="urn:bar" ns:xyz="gsdfsd"/>));

print $scalar, "\n";

ok($scalar);
ok($scalar, qr(<ns:foo), "has ns:foo tag");
ok($scalar, qr(ns:xyz=["']gsdfsd["']), "has ns:xyz attribute");
ok($scalar, qr(xmlns:ns=["']urn:bar["']), "has xmlns attribute");
