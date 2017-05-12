use Test::More tests => 2;

use XML::Generator::DBI;

SKIP: {
    skip "XML::SAX::Writer not installed", 2
        unless eval { require XML::SAX::Writer };
    
    my $output = '';
    my $h = XML::Generator::DBI->new(
        Handler => XML::SAX::Writer->new(Output => \$output),
        Indent => 1,
        );
    ok($h);
    
    $h->start_document({});
    $h->send_start('foo');
    $h->send_start('bar', attr1 => "Attribute 1", attr2 => "Attribute 2");
    $h->send_tag('xyz', 'some content here');
    $h->send_end('bar');
    $h->send_end('foo');
    $h->end_document({});
    
    print $output, "\n";
    
    if (eval { require XML::SAX }) {
        my $p = XML::SAX::ParserFactory->parser;
        eval { $p->parse_string($output) };
        ok(!$@, "Check we can parse the output");
    }
    else {
        skip "XML::SAX not installed", 1;
    }
}
