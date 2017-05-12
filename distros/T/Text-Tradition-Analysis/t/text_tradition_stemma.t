#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use TryCatch;

use_ok( 'Text::Tradition::Stemma' );

# Try to create a bad graph
try {
	my $stemma = Text::Tradition::Stemma->new( dotfile => 't/data/besoin_bad.dot' );
	ok( 0, "Created broken stemma from dotfile with syntax error" );
} catch( Text::Tradition::Error $e ) {
	like( $e->message, qr/^Error trying to parse/, "Syntax error in dot threw exception" );
}

# Create a good graph
my $stemma = Text::Tradition::Stemma->new( dotfile => 't/data/florilegium.dot' );
is( ref( $stemma ), 'Text::Tradition::Stemma', "Created stemma from good dotfile" );
is( scalar $stemma->witnesses, 13, "Found correct number of extant witnesses" );
is( scalar $stemma->hypotheticals, 8, "Found correct number of extant hypotheticals" );
ok( $stemma->has_identifier, "Stemma identifier was found in dot" );
is( $stemma->identifier, 'Coislinianum lineage', "Correct stemma identifier was found in dot" );
my $found_unicode_sigil;
foreach my $h ( $stemma->hypotheticals ) {
	$found_unicode_sigil = 1 if $h eq "\x{3b1}";
}
ok( $found_unicode_sigil, "Found a correctly encoded Unicode sigil" );

# Create an undirected graph
my $udstemma = Text::Tradition::Stemma->new( dotfile => 't/data/besoin_undirected.dot' );
is( ref( $udstemma ), 'Text::Tradition::Stemma', "Created stemma from undirected dotfile" );
is( scalar $udstemma->witnesses, 13, "Found correct number of extant witnesses" );
is( scalar $udstemma->hypotheticals, 12, "Found correct number of hypotheticals" );
ok( $udstemma->is_undirected, "Stemma was recorded as undirected" );
is( $udstemma->identifier, "RHM stemma", "Undirected graph retained its name" );
}




1;
