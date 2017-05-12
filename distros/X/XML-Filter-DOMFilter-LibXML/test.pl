use Test;
BEGIN { plan tests => 2 };

use XML::Filter::DOMFilter::LibXML;
use XML::LibXML::SAX;
use XML::SAX::Writer;

ok(1);

my $input = '<r> <z/> <a/> <b/> <a/> <c/> <d/> </r>';

my $c;
for my $handler (1, 0) {

    print "---\n";

    my $parser ='XML::LibXML::SAX'
        ->new( Handler =>
               'XML::Filter::DOMFilter::LibXML'
               ->new($handler ? ( Handler => 'XML::SAX::Writer::XML'
                                  ->new(
                                        Output => '/dev/null',
                                        Writer => 'XML::SAX::Writer::XML'
                                       )) : (),
                     Process => [ map { $_->[0] => [ sub { shift->(shift) },
                                                     $_->[1], $input] }
                                  [ 'a', sub { warn ++$c, shift } ]
                                ]
                    ));
    $parser->parse_string($input);
}

ok($c == 4);
