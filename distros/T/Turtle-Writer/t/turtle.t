use strict;
use Test::More;

use Turtle::Writer;

is( turtle_literal("x\t\"\n"), '"x\\t\\"\\n"', 'turtle_literal' );
is( turtle_literal("y",'en-CA'), '"y"@en-CA', 'turtle_literal with language' );
is( turtle_literal("y", lang => 'en-CA'), '"y"@en-CA', 'turtle_literal with language' );
is( turtle_literal("y", 'my:uri'), '"y"^^<my:uri>', 'turtle_literal width datatype' );
is( turtle_literal("y", type => 'my:uri'), '"y"^^<my:uri>', 'turtle_literal width datatype' );
is( turtle_literal( [qw(a " c)] ), '"a", "\"", "c"', 'turtle_literal width list' );
is( turtle_literal( [qw(" x)], 'es' ), '"\""@es, "x"@es', 'turtle_literal width list and language' );
is( turtle_literal( [qw(" x)], 'my:x' ), '"\""^^<my:x>, "x"^^<my:x>', 'turtle_literal width list and datatype' );

is ( turtle_literal_list( "0" ), '"0"', 'turtle_literal_list' );
is ( turtle_literal_list( { } ), '', 'turtle_literal_list' );
is ( turtle_literal_list( undef ), '', 'turtle_literal_list' );
is ( turtle_literal_list( qw(a " c) ), '"a", "\"", "c"', 'turtle_literal_list' );
is ( turtle_literal_list( [qw(a " c)] ), '"a", "\"", "c"', 'turtle_literal_list' );
is ( turtle_literal_list( { fr => 'a' } ), '"a"@fr', 'turtle_literal_list' );
is ( turtle_literal_list( { fr => ['a','"'] } ), '"a"@fr, "\""@fr', 'turtle_literal_list' );

foreach ( undef, [ ], "" ) {
    is( turtle_literal( $_ ), "", 'empty literal' );
    is( turtle_literal_list( $_ ), "", 'empty literal list' );
    is( turtle_statement( '<>', 'dc:title' => $_ ), "", 'empty statement' );
}

my $ttl = turtle_statement( '<>', 'dc:title' => '"foo"' );
is( $ttl, "<> dc:title \"foo\" .\n", "turtle_statement" );

$ttl = turtle_statement( undef, 'dc:title' => '"foo"' );
is( $ttl, "[ dc:title \"foo\" ] .\n", "turtle_statement" );

my $exp = <<'RDF';
<http://example.org> dc:creator "Terry Winograd", "Fernando Flores" ;
    a <http://purl.org/ontology/bibo/Document> ;
    dc:title "Understanding Computers and Cognition"@en ;
    dc:date "1987"^^<xs:gYear> .
RDF

my $uri = "http://example.org";
my $got = turtle_statement( 
    "<$uri>",
      "a" => "<http://purl.org/ontology/bibo/Document>",
      "dc:creator" => { # plain literals are escaped
	  	"" => [ "Terry Winograd", "Fernando Flores" ]
      },
      "dc:date" => { "xs:gYear" => "1987" }, # typed literal
      "dc:title" =>
          { en => "Understanding Computers and Cognition" },
      "dc:description" => undef,  # will be ignored
);

$got = [ sort map { $_ =~ s/\.$/;/ } split("\n",$got) ];
$exp = [ sort map { $_ =~ s/\.$/;/ } split("\n",$exp) ];

is_deeply( $got, $exp, 'full example' );

done_testing;
