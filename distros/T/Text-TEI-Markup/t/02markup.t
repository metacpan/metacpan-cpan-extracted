#!/usr/bin/perl;

use strict;
use Encode;
use Convert::Number::Armenian qw/ arm2int /;
use Test::More;
use Test::More::UTF8;
use Test::Warn;
use Text::TEI::Markup qw( to_xml word_tag_wrap );
use XML::LibXML;
use XML::LibXML::XPathContext;

binmode STDERR, ':utf8';
eval { no warnings; binmode $DB::OUT, ':utf8' };

my %opts = (
    file => "t/data/test.txt",
    wrap_words => 0,
    number_conversion => \&arm2int,
    # Using the default template
    # Using the default ( utf8 ) file encoding
);    

my $xml;
ok( $xml = to_xml( %opts ), "Parsed markup without wrapping" );
my $parser = XML::LibXML->new();
my $doc;
ok( $doc = $parser->parse_string( $xml ), "parsed our result XML" );
my $root = $doc->documentElement;

# Some basic tests.  Make sure some header keys are subbed correctly,
# and that there is one body, and that there are the correct number of
# divs and ps and lbs and the like, and that adds & dels & substs have
# the right values.

my @titles;
ok( @titles = $root->getElementsByTagName( 'titleStmt' ), "got title" );
my @title_child = $titles[0]->getChildrenByTagName( 'title' );;
is( $title_child[0]->textContent, "\x{053A}\x{0561}\x{0574}\x{0561}\x{0576}\x{0561}\x{056F}\x{0561}\x{0563}\x{0580}\x{0578}\x{0582}\x{0569}\x{056B}\x{0582}\x{0576}", "title is correct" );
like( $titles[0]->textContent, qr/Tara L Andrews/, "found transcriber" );

my @body = $root->getElementsByTagName( 'body' );
my $body = $body[0];
ok( $body, "found text body" );
my @div = $body->getElementsByTagName( 'div' );
is( scalar @div, 1, "found right number of paragraphs" );
my @pgs = $body->getElementsByTagName( 'p' );
is( scalar @pgs, 2, "found right number of paragraphs" );
my @subst = $body->getElementsByTagName( 'subst' );
is( scalar @subst, 1, "found right number of substitutions" );
my( $found_add, $found_del );
foreach my $schild ( $subst[0]->childNodes() ) {
    if( $schild->nodeName eq 'del' ) {
	$found_del = 1;
	is( $schild->textContent, "\x{570}\x{561}\x{575}\x{578}\x{581}",
	    "right deletion content" );
    } elsif ( $schild->nodeName eq 'add' ) {
	$found_add = 1;
	# Test attribute add
	is( $schild->getAttribute( 'place' ), 'overwrite', 
	    "right add attribute" );
	is( $schild->textContent, 
	    "\x{570}\x{578}\x{57c}\x{578}\x{574}\x{578}\x{581}", 
	    "right add content" );
    }
}
ok( $found_add, "found add tag" );
ok( $found_del, "found del tag" );
# Test tag pass-through
my @supplied = $body->getElementsByTagName( 'supplied' );
is( scalar @supplied, 1, "found pass-through tag" );
is( $supplied[0]->getAttribute( 'reason' ), 'omitted', 
    "pass-through attribute preserved" );
is( $supplied[0]->textContent, "\x{545}", "pass-through content preserved" );

# Pretty well satisfied with non-word-wrapped text.  Go for word wrapping.
my $word_xml;
ok( $word_xml = word_tag_wrap( $xml ), "word-wrap what we have" );
$root = $parser->parse_string( $word_xml )->documentElement;
@body = $root->getElementsByTagName( 'body' );
$body = $body[0];
ok( $body, "found text body" );
my @words = $body->getElementsByTagName( 'w' );
is( scalar @words, 33, "found correct number of simple words" );
my @segwords = $body->getElementsByTagName( 'seg' );
is( scalar @segwords, 27, "found correct number of complex words" );
my( $expan_ct, $ex_ct, $lb_ct, $pb_ct );
foreach my $sw ( @segwords ) {
    is( $sw->getAttribute( 'type' ), "word", "seg has type 'word'" );
    like( $sw->textContent, qr/^\S+$/, "no spaces in segmented word" );
    my @lb = $sw->getElementsByTagName( 'lb' );
    $lb_ct += scalar @lb;
    my @pb = $sw->getElementsByTagName( 'pb' );
    $pb_ct += scalar @pb;
    my @expan = $sw->getElementsByTagName( 'expan' );
    $expan_ct += scalar @expan;
    my @ex = $sw->getElementsByTagName( 'ex' );
    $ex_ct += scalar @ex;
    my @num = $sw->getElementsByTagName( 'num' );
    if( @lb ) {
	# Make sure it isn't the last node
	ok( my $node = $lb[0]->nextSibling, "lb has following sibling" );
    }
    if( @pb ) {
	# Make sure it isn't the last node
	ok( my $node = $pb[0]->nextSibling, "pb has following sibling" );
    }
    if( @expan ) {
	# Make sure it has only text siblings
	my @cnodes = $sw->childNodes();
	foreach my $c ( @cnodes ) {
	    unless( $c->isEqual( $expan[0] ) ) {
		is( $c->nodeName, '#text', "expan sibling is text node" );
	    }
	}
    }
    foreach my $n ( @num ) {
	my $rep = $n->textContent();
	my $val = $n->getAttribute( 'value' );
	is( $val, arm2int( $rep ), "number value sub passthrough works" );
    }
    foreach my $exn ( @ex ) {
	is( $exn->getAttribute( 'resp' ), '#tla', "ex has right resp set" );
    }
}
is( $lb_ct, "4", "right number of lb tags" );
is( $pb_ct, "1", "right number of pb tags" );
is( $ex_ct, "5", "right number of ex tags" );
is( $expan_ct, "14", "right number of expan tags" );

## A separate test for word-tag-wrap, to make sure that we can pass in an XML
## object and get an XML object back.

my $unwrapped_obj = $parser->parse_file( 't/data/test_nowrap.xml' );
my $xpc = XML::LibXML::XPathContext->new( $unwrapped_obj->documentElement );
$xpc->registerNs( 'tei', 'http://www.tei-c.org/ns/1.0' );
word_tag_wrap( $unwrapped_obj );
@words = $xpc->findnodes( '//tei:p/tei:w' );
my @segs = $xpc->findnodes( '//tei:p/tei:seg' );
is( scalar @words, 33, "Got correct number of words" );
is( scalar @segs, 27, "Got correct number of segs" );
foreach my $tag ( qw/ ex expan num abbr subst hi / ) {
	my @wrapped = $xpc->findnodes( "//tei:seg/tei:$tag" );
	my @all = $xpc->findnodes( "//tei:$tag" );
	is( scalar @wrapped, scalar @all, "All $tag tags now inside segs" );
}

## Make sure we can cope with nested text tags
my $nested_obj = $parser->parse_file( 't/data/test_nest.xml' );
word_tag_wrap( $nested_obj );
@words = $xpc->findnodes( '//tei:p/tei:w', $nested_obj->documentElement );
my @nestwords = $xpc->findnodes( '//tei:seg/tei:w' );
is( @words, 297, "Got all words wrapped" );
is( @nestwords, 0, "Did not nest any words" );

# Test a file with spaces in the HEAD tags
my $xml2;
my @NT = <DATA>;
warnings_like {
	$xml2 = to_xml( file => "t/data/test2.txt", 
					template => join( '', @NT ),
					number_conversion => \&arm2int );
} [qr/^\(16\)/], 
	"Got a parse warning on second markup";
ok( $xml2, "Parse of second markup succeeded" );
my $xmlobj2 = $parser->parse_string( $xml2 );
my $xpc2 = XML::LibXML::XPathContext->new( $xmlobj2->documentElement );
$xpc2->registerNs( 'tei', 'http://www.tei-c.org/ns/1.0' );
# The sigil should be 'Q' with no spaces.
my $sigil = $xpc2->findvalue( '//tei:msDesc/attribute::xml:id' );
is( $sigil, 'Q', "Spaces in HEAD were disregarded" );
# The repository should be 'Mekhitarist Library' with no spaces.
my $repo = $xpc2->findvalue( '//tei:repository' );
is( $repo, 'Mekhitarist Library', "Repository got set correctly" );

# Test number generation with meta tags
my @numbers = $xpc2->findnodes( '//tei:num' );
is( scalar @numbers, 5, "Found all expected numbers" );
is( $numbers[0]->getAttribute('value'), 3, "Got correct value for number" );
is( $numbers[0]->getAttribute('type'), 'ordinal', "Got correct type for number" );
is( $numbers[1]->getAttribute('value'), 100, "Got correct value for number" );
is( $numbers[2]->getAttribute('value'), 2, "Got correct value for number" );
is( $numbers[3]->getAttribute('value'), 2, "Got correct value for number" );
is( $numbers[3]->getAttribute('type'), 'ordinal', "Got correct type for number" );
is( $numbers[4]->getAttribute('value'), 1, "Got correct value for number" );

# Test empty hilight field
my @hilights = $xpc2->findnodes( '//tei:hi' );
is( $hilights[0]->getAttribute('rend'), 'DEFAULT', 
	"Default tag got added to empty hilight" );

done_testing();

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<TEI xmlns="http://www.tei-c.org/ns/1.0"
	 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	 xsi:schemaLocation="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng">
  <teiHeader>
	<fileDesc>
	  <titleStmt>
		<title>__TITLE__</title>
		<author>__AUTHOR__</author>
		<respStmt xml:id="__TRANSCRIBERID__">
		  <resp>Transcription by</resp>
		  <name>__TRANSCRIBER__</name>
		</respStmt>
	  </titleStmt>
	  <publicationStmt>
		<p>__PUBLICATIONSTMT__</p>
	  </publicationStmt>
	  <sourceDesc>
		<msDesc xml:id="__SIGIL__">
		  <msIdentifier>
			<settlement>__SETTLEMENT__</settlement>
			<repository>__REPOSITORY__</repository>
			<idno>__IDNO__</idno>
		  </msIdentifier>
		  <p>__PAGES__</p>
		</msDesc>
	  </sourceDesc>
	</fileDesc>
	<encodingDesc>
	  <appInfo>
		<application version="1.0" ident="Text::TEI::Collate"/>
	  </appInfo>
	</encodingDesc>
  </teiHeader>
  <text>
	<body>
__MAIN__
	</body>
  </text>
</TEI>
