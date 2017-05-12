#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Text::TEI::Collate;

my $aligner = Text::TEI::Collate->new();

is( ref( $aligner ), 'Text::TEI::Collate', "Got a Collate object from new()" );
}



# =begin testing
{
use Text::TEI::Collate;
use TryCatch;

my $aligner = Text::TEI::Collate->new();
is( $aligner->distance_sub, \&Text::TEI::Collate::Lang::Default::distance, "Have correct default distance sub" );
my $ok = eval { $aligner->language( 'Armenian' ); };
ok( $ok, "Used existing language module" );
is( $aligner->distance_sub, \&Text::TEI::Collate::Lang::Armenian::distance, "Set correct distance sub" );

$aligner->language( 'default' );
is( $aligner->distance_sub, \&Text::TEI::Collate::Lang::Default::distance, "Back to default distance sub" );

# TODO test Throwable object
try {
    $aligner->language( 'Klingon' );
} catch( Text::TEI::Collate::Error $e ) {
    is( $e->ident, 'bad language module', "Caught the lang module error we expected" );
} catch {
    ok( 0, "FAILED to catch expected exception" );
}
}



# =begin testing
{
use XML::LibXML;

my $aligner = Text::TEI::Collate->new();
$aligner->language( 'Armenian' );

# Test a manuscript with a plaintext source, filename

my @mss = $aligner->read_source( 't/data/plaintext/test1.txt',
	'identifier' => 'plaintext 1',
	);
is( scalar @mss, 1, "Got a single object for a plaintext file");
my $ms = pop @mss;
	
is( ref( $ms ), 'Text::TEI::Collate::Manuscript', "Got manuscript object back" );
is( $ms->sigil, 'A', "Got correct sigil A");
is( scalar( @{$ms->words}), 181, "Got correct number of words in A");

# Test a manuscript with a plaintext source, string
open( T2, "t/data/plaintext/test2.txt" ) or die "Could not open test file";
my @lines = <T2>;
close T2;
@mss = $aligner->read_source( join( '', @lines ),
	'identifier' => 'plaintext 2',
	);
is( scalar @mss, 1, "Got a single object for a plaintext string");
$ms = pop @mss;

is( ref( $ms ), 'Text::TEI::Collate::Manuscript', "Got manuscript object back" );
is( $ms->sigil, 'B', "Got correct sigil B");
is( scalar( @{$ms->words}), 183, "Got correct number of words in B");
is( $ms->identifier, 'plaintext 2', "Got correct identifier for B");

# Test two manuscripts with a JSON source
open( JS, "t/data/json/testwit.json" ) or die "Could not read test JSON";
@lines = <JS>;
close JS;
@mss = $aligner->read_source( join( '', @lines ) );
is( scalar @mss, 2, "Got two objects from the JSON string" );
is( ref( $mss[0] ), 'Text::TEI::Collate::Manuscript', "Got manuscript object 1");
is( ref( $mss[1] ), 'Text::TEI::Collate::Manuscript', "Got manuscript object 2");
is( $mss[0]->sigil, 'MsAJ', "Got correct sigil for ms 1");
is( $mss[1]->sigil, 'MsBJ', "Got correct sigil for ms 2");
is( scalar( @{$mss[0]->words}), 182, "Got correct number of words in ms 1");
is( scalar( @{$mss[1]->words}), 263, "Got correct number of words in ms 2");
is( $mss[0]->identifier, 'JSON 1', "Got correct identifier for ms 1");
is( $mss[1]->identifier, 'JSON 2', "Got correct identifier for ms 2");

# Test a manuscript with an XML source
@mss = $aligner->read_source( 't/data/xml_plain/test3.xml' );
is( scalar @mss, 1, "Got a single object from XML file" );
$ms = pop @mss;

is( ref( $ms ), 'Text::TEI::Collate::Manuscript', "Got manuscript object back" );
is( $ms->sigil, 'BL5260', "Got correct sigil BL5260");
is( scalar( @{$ms->words}), 178, "Got correct number of words in MsB");
is( $ms->identifier, 'London OR 5260', "Got correct identifier for MsB");

my $parser = XML::LibXML->new();
my $doc = $parser->parse_file( 't/data/xml_plain/test3.xml' );
@mss = $aligner->read_source( $doc );
is( scalar @mss, 1, "Got a single object from XML object" );
$ms = pop @mss;

is( ref( $ms ), 'Text::TEI::Collate::Manuscript', "Got manuscript object back" );
is( $ms->sigil, 'BL5260', "Got correct sigil BL5260");
is( scalar( @{$ms->words}), 178, "Got correct number of words in MsB");
is( $ms->identifier, 'London OR 5260', "Got correct identifier for MsB");

## The mss we will test the rest of the tests with.
$aligner->language( 'Greek' );
@mss = $aligner->read_source( 't/data/cx/john18-2.xml' );
is( scalar @mss, 28, "Got correct number of mss from CX file" );
my %wordcount = (
	'base' => 57,
	'P60' => 20,
	'P66' => 55,
	'w1' => 58,
	'w11' => 57,
	'w13' => 58,
	'w17' => 58,
	'w19' => 57,
	'w2' => 58,
	'w21' => 58,
	'w211' => 54,
	'w22' => 57,
	'w28' => 57,
	'w290' => 46,
	'w3' => 56,
	'w30' => 59,
	'w32' => 58,
	'w33' => 57,
	'w34' => 58,
	'w36' => 58,
	'w37' => 56,
	'w38' => 57,
	'w39' => 58,
	'w41' => 58,
	'w44' => 56,
	'w45' => 58,
	'w54' => 57,
	'w7' => 57,
);
foreach( @mss ) {
	is( scalar @{$_->words}, $wordcount{$_->sigil}, "Got correct number of words for " . $_->sigil );
}
}



# =begin testing
{
my $aligner = Text::TEI::Collate->new();
my @mss = $aligner->read_source( 't/data/cx/john18-2.xml' );
my @orig_wordlists = map { $_->words } @mss;
$aligner->align( @mss );
my $cols = 75;
foreach( @mss ) {
	is( scalar @{$_->words}, $cols, "Got correct collated columns for " . $_->sigil);
}
foreach my $i ( 0 .. $#mss ) {
    my $ms = $mss[$i];
    my @old_words = map { $_->canonical_form } @{$orig_wordlists[$i]};
    my @real_words = map { $_->canonical_form } grep { !$_->invisible } @{$ms->words};
    is( scalar @old_words, scalar @real_words, "Manuscript " . $ms->sigil . " has an unchanged word total" );
    foreach my $j ( 0 .. $#old_words ) {
        my $rw = $j < scalar @real_words ? $real_words[$j] : '';
        is( $rw, $old_words[$j], "...word at index $j is correct" );
    }
}
}



# =begin testing
{
use Text::TEI::Collate;

my @test = (
    'the black dog had his day',
    'the white dog had her day',
    'the bright red dog had his day',
    'the bright white cat had her day',
);
my $aligner = Text::TEI::Collate->new();
my @mss = map { $aligner->read_source( $_ ) } @test;
$aligner->align( @mss );
my $base = $aligner->generate_base( @mss );
# Get rid of the specials
pop @$base;
shift @$base;
is( scalar @$base, 8, "Got right number of words" );
is( $base->[0]->word, 'the', "Got correct first word" );
is( scalar $base->[0]->links, 3, "Got 3 links" );
is( scalar $base->[0]->variants, 0, "Got 0 variants" );
is( $base->[1]->word, 'black', "Got correct second word" );
is( scalar $base->[1]->links, 0, "Got 0 links" );
is( scalar $base->[1]->variants, 1, "Got 1 variant" );
is( $base->[1]->get_variant(0)->word, 'bright', "Got correct first variant" );
is( scalar $base->[1]->get_variant(0)->links, 1, "Got a variant link" );
is( $base->[2]->word, 'white', "Got correct second word" );
is( scalar $base->[2]->links, 1, "Got 1 links" );
is( scalar $base->[2]->variants, 0, "Got 0 variants" );
is( $base->[3]->word, 'red', "Got correct third word" );
is( scalar $base->[3]->links, 0, "Got 0 links" );
is( scalar $base->[3]->variants, 1, "Got a variant" );
is( $base->[3]->get_variant(0)->word, 'cat', "Got correct second variant" );
is( scalar $base->[3]->get_variant(0)->links, 0, "Variant has no links" );
is( $base->[4]->word, 'dog', "Got correct fourth word" );
is( scalar $base->[4]->links, 2, "Got 2 links" );
is( scalar $base->[4]->variants, 0, "Got 0 variants" );
is( $base->[5]->word, 'had', "Got correct fifth word" );
is( scalar $base->[5]->links, 3, "Got 3 links" );
is( scalar $base->[5]->variants, 0, "Got 0 variants" );
is( $base->[6]->word, 'his', "Got correct sixth word" );
is( scalar $base->[6]->links, 1, "Got 1 link" );
is( scalar $base->[6]->variants, 1, "Got 1 variant" );
is( scalar $base->[6]->get_variant(0)->links, 1, "Got 1 variant link" );
is( $base->[6]->get_variant(0)->word, 'her', "Got correct third variant");
is( $base->[7]->word, 'day', "Got correct seventh word" );
is( scalar $base->[7]->links, 3, "Got 3 links" );
is( scalar $base->[7]->variants, 0, "Got 0 variants" );
}



# =begin testing
{
use Text::TEI::Collate;
use Text::TEI::Collate::Word;

my $aligner = Text::TEI::Collate->new();

# Set up the base: 'and|B(very|D) white|B(green|C/special|D)'
my @base;
foreach my $w ( qw/ and white / ) {
    push( @base, Text::TEI::Collate::Word->new( 'string' => $w, 'ms_sigil' => 'B' ) );
}
my $v1 = Text::TEI::Collate::Word->new( 'string' => 'very', 'ms_sigil' => 'D' );
$base[0]->add_variant( $v1 );
my $v2 = Text::TEI::Collate::Word->new( 'string' => 'green', 'ms_sigil' => 'C' );
my $v3 = Text::TEI::Collate::Word->new( 'string' => 'special', 'ms_sigil' => 'D' );
$v2->add_variant( $v3 );
$base[1]->add_variant( $v2 );

# Set up the new: 'not very special'
my @new;
foreach my $w ( qw/ not very special / ) {
    push( @new, Text::TEI::Collate::Word->new( 'string' => $w, 'ms_sigil' => 'E' ) );
}

# Set up the base_idx
my $base_idx = { $v1 => 0, $v2 => 1, $v3 => 1 };

# Get the right matches in the first place
$aligner->make_fuzzy_matches( [ @base, $v1, $v2, $v3 ], \@new );
my @matches = $aligner->_match_variants( [ $v1, $v2, $v3 ], \@new, $base_idx );
is( scalar @matches, 2, "Got two matches from constructed case" );
is_deeply( $matches[0], [ 0, 1, $v1 ], "First match is correct" );
is_deeply( $matches[1], [ 1, 2, $v3 ], "Second match is correct" );

# Now do the real testing
my( $nb, $nn ) = $aligner->_add_variant_matches( \@matches, \@base, \@new, $base_idx );
is( scalar @$nb, 3, "Got three base words" );
is( scalar @$nn, 3, "Got three new words" );
is( $nb->[0], $aligner->empty_word, "Empty word at front of base" );
}



# =begin testing
{
use Test::More::UTF8;
use Text::TEI::Collate;
use Text::TEI::Collate::Word;
use Text::WagnerFischer;

my $base_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => 'հարիւրից' );
my $variant_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => 'զ100ից' );
my $match_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => 'զհարիւրից' );
my $new_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => '100ից' );
my $different_word = Text::TEI::Collate::Word->new( ms_sigil => 'A', string => 'անգամ' );

# not really Greek, but we want Text::WagnerFischer::distance here
my $aligner = Text::TEI::Collate->new( 'language' => 'Greek' ); 
$base_word->add_variant( $variant_word );
is( $aligner->word_match( $base_word, $match_word), $base_word, "Matched base word" );
is( $aligner->word_match( $base_word, $new_word), $variant_word, "Matched variant word" );
is( $aligner->word_match( $base_word, $different_word), undef, "Did not match irrelevant words" );

my( $ms1 ) = $aligner->read_source( 'Jn bedwange harde swaer Doe riepen si op gode met sinne' );
my( $ms2 ) = $aligner->read_source( 'Jn bedvanghe harde suaer. Doe riepsi vp gode met sinne.' );
$aligner->make_fuzzy_matches( $ms1->words, $ms2->words );
is( scalar keys %{$aligner->{fuzzy_matches}}, 15, "Got correct number of vocabulary words" );
my %unique;
map { $unique{$_} = 1 } values %{$aligner->{fuzzy_matches}};
is( scalar keys %unique, 11, "Got correct number of fuzzy matching words" );
}



# =begin testing
{
use Test::More::UTF8;
use Text::TEI::Collate;

my $aligner = Text::TEI::Collate->new();
ok( $aligner->_is_near_word_match( 'Արդ', 'Արդ' ), "matched exact string" );
ok( $aligner->_is_near_word_match( 'հաւասն', 'զհաւասն' ), "matched near-exact string" );
ok( !$aligner->_is_near_word_match( 'հարիւրից', 'զ100ից' ), "did not match differing string" );
ok( !$aligner->_is_near_word_match( 'ժամանակական', 'զշարագրական' ), "did not match differing string 2" );
ok( $aligner->_is_near_word_match( 'ընթերցողք', 'ընթերցողսն' ), "matched near-exact string 2" );
ok( $aligner->_is_near_word_match( 'պատմագրացն', 'պատգամագրացն' ), "matched pretty close string" );
ok( $aligner->_is_near_word_match( 'αι̣τια̣ν̣', 'αιτιαν' ), "matched string one direction" );
ok( $aligner->_is_near_word_match( 'αιτιαν', 'αι̣τια̣ν̣' ), "matched string other direction" );
}



# =begin testing
{
use Text::TEI::Collate;

my $aligner = Text::TEI::Collate->new();
my( $base ) = $aligner->read_source( 'The black cat' );
my( $other ) = $aligner->read_source( 'The black and white little cat' );
$aligner->align( $base, $other );
# Check length
is( scalar @{$base->words}, 8, "Got six columns plus top and tail" );
is( scalar @{$other->words}, 8, "Got six columns plus top and tail" );
# Check contents
is( $base->words->[-1]->special, 'END', "Got ending mark at end" );
is( $base->words->[0]->special, 'BEGIN', "Got beginning mark at start" );
is( $other->words->[-1]->special, 'END', "Got ending mark at end" );
is( $other->words->[0]->special, 'BEGIN', "Got beginning mark at start" );
# Check empty spaces
my $base_exp = [ 'BEGIN', 'the', 'black', '', '', '', 'cat', 'END' ];
my $other_exp = [ 'BEGIN', 'the', 'black', 'and', 'white', 'little', 'cat', 'END' ];
my @base_str = map { $_->printable } @{$base->words};
my @other_str = map { $_->printable } @{$other->words};
is_deeply( \@base_str, $base_exp, "Right sequence of words in base" );
is_deeply( \@other_str, $other_exp, "Right sequence of words in other" );

my @test = (
    'The black dog chases a red cat.',
    'A red cat chases the black dog.',
    'A red cat chases the yellow dog<',
);
my @mss = map { $aligner->read_source( $_ ) } @test;
$aligner->align( @mss );

$base = $mss[0];
$other = $mss[2];
is( scalar @{$base->words}, 13, "Got 11 columns plus top and tail" );
is( scalar @{$other->words}, 13, "Got 11 columns plus top and tail" );
$base_exp = [ 'BEGIN', 'the', 'black', 'dog', 'chases', 'a', 'red', 'cat', 'END', '', '', '', '' ];
$other_exp = [ '', '', '', '', 'BEGIN', 'a', 'red', 'cat', 'chases', 'the', 'yellow', 'dog', 'END' ];
@base_str = map { $_->printable } @{$base->words};
@other_str = map { $_->printable } @{$other->words};
is_deeply( \@base_str, $base_exp, "Right sequence of words in base" );
is_deeply( \@other_str, $other_exp, "Right sequence of words in other" );
is( $base->words->[-5]->special, 'END', "Got ending mark at end for base" );
is( $base->words->[0]->special, 'BEGIN', "Got beginning mark at start for base" );
is( $other->words->[-1]->special, 'END', "Got ending mark at end for other" );
is( $other->words->[4]->special, 'BEGIN', "Got beginning mark at start for other" );
}



# =begin testing
{
my $aligner = Text::TEI::Collate->new();
my @mss = $aligner->read_source( 't/data/cx/john18-2.xml' );
$aligner->align( @mss );
my $jsondata = $aligner->to_json( @mss );
ok( exists $jsondata->{alignment}, "to_json: Got alignment data structure back");
my @wits = @{$jsondata->{alignment}};
is( scalar @wits, 28, "to_json: Got correct number of witnesses back");
# Without the beginning and end marks, we have 75 word spots.
my $columns = 73;
foreach ( @wits ) {
	is( scalar @{$_->{tokens}}, $columns, "to_json: Got correct number of words back for witness")
}
}



# =begin testing
{
use IO::String;
use Text::CSV_XS;
use Test::More::UTF8;

my $aligner = Text::TEI::Collate->new();
my @mss = $aligner->read_source( 't/data/cx/john18-2.xml' );
$aligner->align( @mss );
my $csvstring = $aligner->to_csv( @mss );
ok( $csvstring, "Got a CSV string returned" );
# Parse the CSV data and test that it parsed
my $io = IO::String->new( $csvstring );
my $csv = Text::CSV_XS->new( { binary => 1 } );

# Test the number of columns in the first row
my $sigilrow = $csv->getline( $io );
ok( $sigilrow, "Got a row" );
is( scalar @$sigilrow, 28, "Got the correct number of witnesses" );

# Test the number of rows in the table
my $rowctr = 0;
while( my $row = $csv->getline( $io ) ) {
    is( scalar @$row, 28, "Got a reading for all columns" );
    $rowctr++;
    if( $rowctr == 1 ) {
        # Test that we are getting our encoding right
        is( $row->[0], "λέγει", "Got the right first word" );
    }
}
is( $rowctr, 73, "Got expected number of rows in CSV" );
}



# =begin testing
{
use Text::TEI::Collate;
use XML::LibXML::XPathContext;
# Get an alignment to test with
my $testdir = "t/data/xml_plain";
opendir( XF, $testdir ) or die "Could not open $testdir";
my @files = readdir XF;
my @mss;
my $aligner = Text::TEI::Collate->new(
	'fuzziness' => '50',
	'language' => 'Armenian',
	'title' => 'Test Armenian collation',
	);
foreach ( sort @files ) {
	next if /^\./;
	push( @mss, $aligner->read_source( "$testdir/$_" ) );
}
$aligner->align( @mss );

my $doc = $aligner->to_tei( @mss );
is( ref( $doc ), 'XML::LibXML::Document', "Made TEI document header" );
my $xpc = XML::LibXML::XPathContext->new( $doc->documentElement );
$xpc->registerNs( 'tei', $doc->documentElement->namespaceURI );

# Test the creation of a document header from TEI files
my @witdesc = $xpc->findnodes( '//tei:witness/tei:msDesc' );
is( scalar @witdesc, 5, "Found five msdesc nodes");
my $title = $xpc->findvalue( '//tei:titleStmt/tei:title' );
is( $title, $aligner->title, "TEI doc title set correctly" );

# Test the creation of apparatus entries
my @apps = $xpc->findnodes( '//tei:app' );
is( scalar @apps, 107, "Got the correct number of app entries");
my @words_not_in_app = $xpc->findnodes( '//tei:body/tei:div/tei:p/tei:w' );
is( scalar @words_not_in_app, 175, "Got the correct number of matching words");
my @details = $xpc->findnodes( '//tei:witDetail' );
my @detailwits;
foreach ( @details ) {
	my $witstr = $_->getAttribute( 'wit' );
	push( @detailwits, split( /\s+/, $witstr ));
}
is( scalar @detailwits, 13, "Found the right number of witness-detail wits");

# TODO test the reconstruction of witnesses from the parallel-seg.
}



# =begin testing
{
use lib 't/lib';
use Text::TEI::Collate;
use XML::LibXML::XPathContext;

eval 'require Graph::Easy;';
unless( $@ ) {
# Get an alignment to test with
my $testdir = "t/data/xml_plain";
opendir( XF, $testdir ) or die "Could not open $testdir";
my @files = readdir XF;
my @mss;
my $aligner = Text::TEI::Collate->new(
	'fuzziness' => '50',
	'language' => 'Armenian',
	);
foreach ( sort @files ) {
	next if /^\./;
	push( @mss, $aligner->read_source( "$testdir/$_" ) );
}
$aligner->align( @mss );

my $graph = $aligner->to_graph( @mss );

is( ref( $graph ), 'Graph::Easy', "Got a graph object from to_graph" );
is( scalar( $graph->nodes ), 380, "Got the right number of nodes" );
is( scalar( $graph->edges ), 992, "Got the right number of edges" );
}
}




1;
