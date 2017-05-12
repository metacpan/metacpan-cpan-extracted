# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Parser-Nodes.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 39 ;
BEGIN { use_ok('XML::Parser::Nodes') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $msmxml =<<eof ;
<?xml version="1.0"?>
<catalog>
   <book id="bk101">
      <author>Gambardella, Matthew</author>
      <title>XML Developer's Guide</title>
      <genre>Computer</genre>
      <price>44.95</price>
      <publish_date>2000-10-01</publish_date>
      <description>An in-depth look at creating applications 
      with XML.</description>
   </book>
   <book id="bk102">
      <author>Ralls, Kim</author>
      <title>Midnight Rain</title>
      <genre>Fantasy</genre>
      <price>5.95</price>
      <publish_date>2000-12-16</publish_date>
      <description>A former architect battles corporate zombies, 
      an evil sorceress, and her own childhood to become queen 
      of the world.</description>
   </book>
   <book id="bk103">
      <author>Corets, Eva</author>
      <title>Maeve Ascendant</title>
      <genre>Fantasy</genre>
      <price>5.95</price>
      <publish_date>2000-11-17</publish_date>
      <description>After the collapse of a nanotechnology 
      society in England, the young survivors lay the 
      foundation for a new society.</description>
   </book>
   <book id="bk104">
      <author>Corets, Eva</author>
      <title>Oberon's Legacy</title>
      <genre>Fantasy</genre>
      <price>5.95</price>
      <publish_date>2001-03-10</publish_date>
      <description>In post-apocalypse England, the mysterious 
      agent known only as Oberon helps to create a new life 
      for the inhabitants of London. Sequel to Maeve 
      Ascendant.</description>
   </book>
   <book id="bk105">
      <author>Corets, Eva</author>
      <title>The Sundered Grail</title>
      <genre>Fantasy</genre>
      <price>5.95</price>
      <publish_date>2001-09-10</publish_date>
      <description>The two daughters of Maeve, half-sisters, 
      battle one another for control of England. Sequel to 
      Oberon's Legacy.</description>
   </book>
   <book id="bk106">
      <author>Randall, Cynthia</author>
      <title>Lover Birds</title>
      <genre>Romance</genre>
      <price>4.95</price>
      <publish_date>2000-09-02</publish_date>
      <description>When Carla meets Paul at an ornithology 
      conference, tempers fly as feathers get ruffled.</description>
   </book>
   <book id="bk107">
      <author>Thurman, Paula</author>
      <title>Splish Splash</title>
      <genre>Romance</genre>
      <price>4.95</price>
      <publish_date>2000-11-02</publish_date>
      <description>A deep sea diver finds true love twenty 
      thousand leagues beneath the sea.</description>
   </book>
   <book id="bk108">
      <author>Knorr, Stefan</author>
      <title>Creepy Crawlies</title>
      <genre>Horror</genre>
      <price>4.95</price>
      <publish_date>2000-12-06</publish_date>
      <description>An anthology of horror stories about roaches,
      centipedes, scorpions  and other insects.</description>
   </book>
   <book id="bk109">
      <author>Kress, Peter</author>
      <title>Paradox Lost</title>
      <genre>Science Fiction</genre>
      <price>6.95</price>
      <publish_date>2000-11-02</publish_date>
      <description>After an inadvertant trip through a Heisenberg
      Uncertainty Device, James Salway discovers the problems 
      of being quantum.</description>
   </book>
   <book id="bk110">
      <author>O'Brien, Tim</author>
      <title>Microsoft .NET: The Programming Bible</title>
      <genre>Computer</genre>
      <price>36.95</price>
      <publish_date>2000-12-09</publish_date>
      <description>Microsoft's .NET initiative is explored in 
      detail in this deep programmer's reference.</description>
   </book>
   <book id="bk111">
      <author>O'Brien, Tim</author>
      <title>MSXML3: A Comprehensive Guide</title>
      <genre>Computer</genre>
      <price>36.95</price>
      <publish_date>2000-12-01</publish_date>
      <description>The Microsoft MSXML3 parser is covered in 
      detail, with attention to XML DOM interfaces, XSLT processing, 
      SAX and more.</description>
   </book>
   <book id="bk112">
      <author>Galos, Mike</author>
      <title>Visual Studio 7: A Comprehensive Guide</title>
      <genre>Computer</genre>
      <price>49.95</price>
      <publish_date>2001-04-16</publish_date>
      <description>Microsoft Visual Studio 7 is explored in depth,
      looking at how Visual Basic, Visual C++, C#, and ASP+ are 
      integrated into a comprehensive development 
      environment.</description>
   </book>
</catalog>
eof

my $request = {
    'QBMSXML' => {
        'MsgsRq' => [ 
            {
                'CreditCard' => {
                    'Amount' => '10.00',
                    'Year' => '2012',
                    'Number' => '4111111111111111',
                    'RequestID' => '546696356386',
                    'Month' => '12',
                    'CardPresent' => 'false'
                    }
                },
            {
                'CreditCard' => {
                    'Amount' => '20.00',
                    'Year' => '2014',
                    'Number' => '4123111111111111',
                    'RequestID' => '546696356387',
                    'Month' => '8',
                    'CardPresent' => 'false'
                    }
                }
            ],
        'Signon' => {
            'Desktop' => {
                'DateTime' => '2012-02-29T12:40:09',
                'Ticket' => 'gas8p9ee-re2s9old-ref2i6t',
                'Login' => 'tqis.com'
                }
            }
        }
    } ;

my $parser = 'XML::Parser' ;
my $nodes = 'XML::Parser::Nodes' ;
my $xmlpp = $parser->new( Style => 'Nodes' ) ;
is( ref $xmlpp, $parser, 'XML::Parser creation' ) ;

my $xml = $xmlpp->parse( $msmxml ) ;
is( ref $xml, $nodes, 'parse() #1' ) ;
is( $xml->[1], 'catalog', 'parse() #2' ) ;

my @list = $xml->childlist ;
is( @list, 1, 'childlist() #1' ) ;
is( $list[0], 'catalog', 'childlist() #2' ) ;

my $child = $xml->childnode( $list[0] ) ;
is( ref $child, $nodes, 'childnode() #1' ) ;
is( scalar $child->childlist, 12, 'childnode() #2' ) ;

my @tree = $xml->tree ;
is( @tree, 85, 'tree() #1' ) ;
my @grep = grep $_ eq 'catalog/book/title', @tree ;
is( @grep, 12, 'tree() #2' ) ;
@tree = $child->tree ;
is( @tree, 84, 'tree() #3' ) ;

my @node = $xml->nodebykey( $grep[0] ) ;
is( @node, 1, 'nodebykey() #1' ) ;
is( ref $node[0], $nodes, 'nodebykey() #2' ) ;
my @elements = $node[0]->childnodes ;
is( @elements, 0, 'nodebykey() #3' ) ;

like( $node[0]->gettext, qr/\S/, 'gettext() #1' ) ;
unlike( $child->gettext, qr/\S/, 'gettext() #2' ) ;

my @books = $child->childnodes ;
is( @books, 12, 'childnodes() #1' ) ;
is( ref $books[0], 'ARRAY', 'childnodes() #2' ) ;
is( $books[0][0], 'book', 'childnodes() #3' ) ;
is( ref $books[0][1], $nodes, 'childnodes() #4' ) ;

ok( exists $books[0][1]->getattributes->{id}, 'getattributes() #1' ) ;

my $recursion = $xml->getdata('catalog'
		)->getdata('book'
		)->getdata('price') ;

is( ref $recursion, $nodes, "recursion #1" ) ;
like( $recursion->gettext, qr/\S/, 'recursion #2' ) ;

my $header =<<'xml' ;
<?xml version="1.0"?>
xml
my $dump = $header .$xml->dump ;
is( $dump, $msmxml, "dump()" ) ;

my $xmlreq = XML::Parser::Nodes->pl2xml( $request ) ;
is( ($xmlreq->childnodes )[0]->[0], 'perldata', 'pl2xml() #1' ) ;
@tree = $xmlreq->tree ;
is( @tree, 33, 'pl2xml() #2' ) ;

$dump = $xmlreq->dump ;
my @match = ( '<arrayref memory_address="0x[0-9a-f]*">',
		'<item key="RequestID">546696356386</item>',
		'<MsgsRq>.*</MsgsRq>.*<MsgsRq>.*</MsgsRq>',
		'<Ticket>gas8p9ee-re2s9old-ref2i6t</Ticket>',
		) ;
like( $dump, qr/$match[0]/s, 'pl2xml() #3' ) ;
like( $dump, qr/$match[1]/s, 'pl2xml() #4' ) ;

$dump = $xmlreq->nvpdump ;
like( $dump, qr/$match[2]/s, 'nvpdump() #1' ) ;
like( $dump, qr/$match[3]/s, 'nvpdump() #2' ) ;

$xml = new XML::Parser::Nodes $msmxml ;
$dump = $header .$xml->dump ;
is( $dump, $msmxml, "new() #1" ) ;

my @path = split m|/|, $0 ;
pop @path ;
my $fn = join '/', @path, 'XML-Parser-Nodes.xml' ;
local( *H ) ;
my $fh = *H ;

ok( open( $fh, $fn ), 'can\'t open xml file' ) ;
my $buff = '' ;
do { 
	undef $/ ;
	$buff = <$fh> ;
	} ;
	
is( $buff, $msmxml, 'xml file contents' ) ;

$xml = $xmlpp->parsefile( $fn ) ;
$dump = $header .$xml->dump ;
is( $dump, $msmxml, "parsefile()" ) ;

$xml = new XML::Parser::Nodes $fn ;
$dump = $header .$xml->dump ;
is( $dump, $msmxml, "new() #2" ) ;

my $parent = $xml->wrapper('parent') ;
@list = $parent->childlist ;
is( @list, 1, 'wrapper() #1' ) ;
is( $list[0], 'parent', 'wrapper() #2' ) ;

@list = $parent->childnode( $list[0] )->childlist ;
is( @list, 1, 'wrapper() #3' ) ;
is( $list[0], 'catalog', 'wrapper() #4' ) ;

1
