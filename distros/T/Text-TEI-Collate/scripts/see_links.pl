#!/usr/bin/perl -w

use strict;
use lib 'lib';
use Data::Dumper;
use Text::TEI::Collate;
use utf8;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

my $type = shift @ARGV;
unless( $type eq 'txt' ) {
    unshift( @ARGV, $type );
    $type = 'xml';
}

my( @files ) = @ARGV;

# and how fuzzy a match we can tolerate.
my $fuzziness = "50";  # this is n%

my $aligner = Text::TEI::Collate->new();

my @manuscripts;
foreach ( @files ) {
    push( @manuscripts, $aligner->read_source( $_ ) );
}
my @results = $aligner->align( @manuscripts );

# Get the new base.  This should have all the links.
my $initial_base = $aligner->generate_base( map { $_->words } @results );

foreach my $idx ( 0 .. $#{$initial_base} ) {
    my $word_obj = $initial_base->[$idx];
    next if $word_obj->word eq '';  # not a real word; no links
    # How many words should there be in this column?
    my $all_words = grep { $_->words->[$idx]->word ne '' } @results;
    my @links = $word_obj->links;
    my @variants = $word_obj->variants;
    my $words_so_far = 1 + scalar( @links ) + scalar ( @variants );
    printf( "Word %s (%s) has%s\n", 
	    $word_obj->word, $word_obj->ms_sigil,
	    ( scalar( @links ) || scalar( @variants ) ) ? ':' 
	    : ' a single witness'
	);
    print "\tLinks - " . join( ", ", map { sprintf( "%s (%s)", $_->word, $_->ms_sigil ) } @links ) . "\n" if @links;
    if( @variants ) {
	print "\tVariants - " . join( ", ", map { sprintf( "%s (%s)", $_->word, $_->ms_sigil ) } @variants ) . "\n";
	foreach( @variants ) {
	    my @vlinks = $_->links;
	    $words_so_far += scalar @vlinks;
	    print "\t\t- variant " . $_->word . " has links " 
		. join( ", ", map { sprintf( "%s (%s)", $_->word, $_->ms_sigil ) } @vlinks ) . "\n"
		if @vlinks;
	}
    }

    print "MISMATCH: Found $words_so_far / $all_words in link nesting\n"
	unless $words_so_far == $all_words;
}
    
print "Done.\n";




