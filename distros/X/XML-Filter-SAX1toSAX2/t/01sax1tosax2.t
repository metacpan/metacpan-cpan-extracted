use Test;
use XML::Filter::SAX1toSAX2;
BEGIN {
    eval {
        require XML::SAX::Writer;
        require XML::Parser::PerlSAX;
    };
    if ($@) {
        plan tests => 0;
        exit(0);
    }
    plan tests => 5;
}

my $scalar = '';

my $sax = XML::Parser::PerlSAX->new(
    Handler => XML::Filter::SAX1toSAX2->new(
        Handler => XML::SAX::Writer->new(
            Output => \$scalar
        )
    )
);

ok($sax);

$sax->parse(Source => { String =>  q(<ns:foo xmlns:ns="urn:bar" ns:xyz="gsdfsd"/>) });

print $scalar, "\n";

ok($scalar);
ok($scalar, qr(<ns:foo), "has ns:foo tag");
ok($scalar, qr(ns:xyz=["']gsdfsd["']), "has ns:xyz attribute");
ok($scalar, qr(xmlns:ns=["']urn:bar["']), "has xmlns attribute");
