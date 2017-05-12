#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Text::TEI::Collate;
use XML::LibXML;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

my $parser = XML::LibXML->new();
my $filepath = "t/data/cx";
my @files = qw/ examples beckett darwin /;

#### First test the simple examples
my @expected_rows = qw/ 6 11 7 9 8 3 7 5 6 8 7 7 17 12 9 20 10 23 26 9 25 10 /;
my $answer = [
    {   # test 1
        rows => 6,
        mss => { A => { 'begin' => 0, 'end' => 7 },
                 B => { 'begin' => 0, 'end' => 7 }, 
                 C => { 'begin' => 0, 'end' => 7 },
                 D => { 'begin' => 0, 'end' => 7 },
                 E => { 'begin' => 0, 'end' => 7 } },
        common => [ 1, 2, 6 ],
    },
    {   # test 2
        rows => 11,
        mss => { A => { 'begin' => 0, 'end' => 8 },
                 B => { 'begin' => 4, 'end' => 12 },
                 C => { 'begin' => 4, 'end' => 12 } },
        common => [ 5, 6, 7 ], 
    },
    {   # test 3
        rows => 7,
        mss => { A => { 'begin' => 0, 'end' => 8 },
                 B => { 'begin' => 0, 'end' => 8 },
                 C => { 'begin' => 0, 'end' => 8 } },
        common => [ 1, 2, 4, 5, 6, 7 ], 
    },
    {   # test 4
        rows => 9,
        mss => { A => { 'begin' => 0, 'end' => 10 },
                 B => { 'begin' => 0, 'end' => 10 },
                 C => { 'begin' => 0, 'end' => 10 } },
        common => [ 1, 2, 6, 7, 8, 9 ], 
    },
    # ...TODO and on for the rest
];

my $doc = $parser->parse_file( "$filepath/examples.xml" );
# Take each example in turn and parse it.
my $n = 0;
foreach my $tc ( $doc->documentElement->getElementsByTagName( 'example' ) ) {
    my @witstrs = map { $_->textContent } $tc->getChildrenByTagName( 'witness' );
    my $aligner = Text::TEI::Collate->new();
    my @mss;
    foreach ( $tc->getChildrenByTagName( 'witness' ) ) {
        push( @mss, $aligner->read_source( $_->textContent,
              'sigil' => $_->getAttribute( 'id' ) ) );
    }
    my @orig_wordlists = map { $_->words } @mss;
    $aligner->align( @mss );
    my $wordcount = $expected_rows[$n];
    my $a;
    if( scalar @$answer > $n ) {
        # Use the answer hash
        $a = $answer->[$n];
        $wordcount = $a->{rows};
    }
    foreach( @mss ) {
        is( scalar @{$_->words}, $wordcount+2, 
            "Got all expected rows in test $n, ms " . $_->sigil );
        if( $a ) {
            my $bw = $_->words->[ $a->{mss}->{$_->sigil}->{'begin'} ];
            my $ew = $_->words->[ $a->{mss}->{$_->sigil}->{'end'} ];
            is( $bw->printable, 'BEGIN', "Begins correctly" );
            is( $ew->printable, 'END', "Begins correctly" );
        }
    }
    foreach my $i ( 0 .. $#mss ) {
        my $ms = $mss[$i];
        my @old_words = map { $_->canonical_form } @{$orig_wordlists[$i]};
        my @real_words = map { $_->canonical_form } grep { !$_->invisible } @{$ms->words};
        is( scalar @old_words, scalar @real_words, 
            "Manuscript " . $ms->sigil . " has an unchanged word total" );
        foreach my $j ( 0 .. $#old_words ) {
            my $rw = $j < scalar @real_words ? $real_words[$j] : '';
            is( $rw, $old_words[$j], "...word at index $j is correct" );
        }
    }
    if( $a ) {
        # Check that the fixed columns are the same.
        foreach my $idx ( @{$a->{common}} ) {
            my %unique;
            map { $unique{ $_->words->[$idx]->printable } = 1 } @mss;
            is( keys %unique, 1, "Common point at $idx is common" );
        }
    }    
    $n++;
}

# TODO Test Beckett and Darwin as well

done_testing();

