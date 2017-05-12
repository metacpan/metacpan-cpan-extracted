use strict;
use Test::More;
use XML::Struct::Writer;
use Encode;

my $writer = XML::Struct::Writer->new;
my $struct = [
    greet => { }, [
        "Hello, ",
        [ emph => { color => "blue" } , [ "World" ] ],
        "!"
    ]
];
my $dom = $writer->writeDocument( $struct );
isa_ok $dom, 'XML::LibXML::Document';
my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<greet>Hello, <emph color="blue">World</emph>!</greet>
XML
is $dom->serialize, $xml, 'writeDocument via DOM';

my $str = "";
XML::Struct::Writer->new( to => \$str )->writeDocument($struct);
is $str, $xml, 'writeDocument via SAX';

$struct = [ doc => { a => 1 }, [ "\x{2603}" ] ]; 
$xml = encode("UTF-8", <<XML);
<?xml version="1.0" encoding="UTF-8"?>
<doc a="1">\x{2603}</doc>
XML

$dom = $writer->writeDocument($struct);
is $dom->serialize, $xml, 'writeDocument with UTF-8 via DOM';
$str = "";
XML::Struct::Writer->new( to => \$str )->writeDocument($struct);
is $str, $xml, 'writeDocument with UTF-8 via SAX';

$str = "";
XML::Struct::Writer->new( to => \$str, xmldecl => 0, pretty => 1 )->writeDocument($struct);
$xml = encode("UTF-8", "<doc a=\"1\">\x{2603}</doc>\n");
is $str, $xml, 'omit xml declaration';

$struct = [
    doc => [ 
        [ name => [ "alice" ] ],
        [ name => [ "bob" ] ],
    ] 
];
$xml = <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<doc>
  <name>alice</name>
  <name>bob</name>
</doc>
XML
$writer->attributes(0);
$dom = $writer->writeDocument($struct);
is $dom->serialize(1), $xml, "writeDocument indented, no attributes";
$str = "";
XML::Struct::Writer->new( to => \$str, pretty => 1, attributes => 0 )->writeDocument($struct);
is $str, $xml, 'writeDocument pretty, no attributes via SAX';

{
    package MyHandler;
    use Moo;
    has buf => (is => 'rw', default => sub { [ ] });
    sub start_document { push @{$_[0]->buf}, "start" }
    sub start_element {  push @{$_[0]->buf}, $_[1] }
    sub end_element {  push @{$_[0]->buf}, $_[1] }
    sub characters { push @{$_[0]->buf}, $_[1] }
    sub end_document { push @{$_[0]->buf}, "end"}
    sub result { $_[0]->buf }
}

$writer = XML::Struct::Writer->new( handler => MyHandler->new );
$xml = $writer->write( [ "foo", { x => 1 }, [ ["bar"], "text" ] ] );
is_deeply $xml, [
    "start",
    { Name => "foo", Attributes => { x => 1 } },
    { Name => "bar" },
    { Name => "bar" },
    { Data => "text" },
    { Name => "foo" },
    "end"
], 'custom handler';

$writer->xmldecl(0);
$writer->to(\$str);
$writer->write( [ "foo", { x => 1 } ] );
is $str, "<foo x=\"1\"/>\n", 'reset to/handler';

done_testing;
