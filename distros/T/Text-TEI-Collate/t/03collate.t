#!/usr/bin/perl -w

use strict;
use File::Basename;
use Test::More 'no_plan';
use Text::TEI::Collate;
use utf8;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

# Find the test files.
my $dirname = dirname( $0 );
my $testdir_plain = "$dirname/data/plaintext";
my $testdir_xml = "$dirname/data/xml_plain";
my $testdir_xmlfull = "$dirname/data/xml_word";

# Set the expected values.
my $expected_word_length = 282;

# Test the plaintext files
my $aligner_plain = Text::TEI::Collate->new( 'fuzziness' => 50, 
                                             'language' => 'Armenian' );
opendir( PLAIN, "$testdir_plain" ) or die "Could not find plaintext test files: $@";
my @plain_fn;
while( my $fn = readdir PLAIN ) {
    next unless $fn =~ /\.txt$/;
    push( @plain_fn, "$testdir_plain/$fn" );
}
my @plain_mss;
foreach ( sort @plain_fn ) {
    push( @plain_mss, $aligner_plain->read_source( $_ ) );
}
$aligner_plain->align( @plain_mss );
is( scalar @plain_mss, 5, "Returned five objects" );
foreach( @plain_mss ) {
    is( ref $_, 'Text::TEI::Collate::Manuscript', "Object of correct type" );
    is( ref $_->words, 'ARRAY', "Object has words array" );
    is( ref $_->words->[0], 'Text::TEI::Collate::Word', "Words array has words" );
    is( scalar @{$_->words}, $expected_word_length, "Words array for plaintext is correct length" );
}

# Test the freeform XML files
my $aligner_xml = Text::TEI::Collate->new( 'fuzziness' => 50, 
                                           'language' => 'Armenian' );
opendir( XML, "$testdir_xml" ) or die "Could not find XML test files: $@";
my @xml_fn;
while( my $fn = readdir XML ) {
    next unless $fn =~ /\.xml$/;
    push( @xml_fn, "$testdir_xml/$fn" );
}
my @xml_mss;
foreach ( sort @xml_fn ) {
    push( @xml_mss, $aligner_plain->read_source( $_ ) );
}
$aligner_xml->align( @xml_mss );
is( scalar @xml_mss, 5, "Returned five objects" );
foreach( @xml_mss ) {
    is( ref $_, 'Text::TEI::Collate::Manuscript', "Object of correct type" );
    is( ref $_->words, 'ARRAY', "Object has words array" );
    is( ref $_->words->[0], 'Text::TEI::Collate::Word', "Words array has words" );
    is( scalar @{$_->words}, $expected_word_length, "Words array for XML is correct length" );
}
# TODO Check for the right number and sort of divisional markers.

# Test the word-wrapped XML files.  These have varied a little from the others.
$expected_word_length = 280;
my $aligner_xmlfull = Text::TEI::Collate->new( 'fuzziness' => 50, 
                                               'language' => 'Armenian' );
opendir( XMLFULL, "$testdir_xmlfull" ) or die "Could not find xmlfulltext test files: $@";
my @xmlfull_fn;
while( my $fn = readdir XMLFULL ) {
    next unless $fn =~ /\.xml$/;
    push( @xmlfull_fn, "$testdir_xmlfull/$fn" );
}
my @xmlfull_mss;
foreach ( sort @xmlfull_fn ) {
    push( @xmlfull_mss, $aligner_xmlfull->read_source( $_ ) );
}
$aligner_xml->align( @xmlfull_mss );
is( scalar @xmlfull_mss, 5, "Returned five objects" );
foreach( @xmlfull_mss ) {
    is( ref $_, 'Text::TEI::Collate::Manuscript', "Object of correct type" );
    is( ref $_->words, 'ARRAY', "Object has words array" );
    is( ref $_->words->[0], 'Text::TEI::Collate::Word', "Words array has words" );
    is( scalar @{$_->words}, $expected_word_length, "Words array for wrapped XML is correct length" );
}
# TODO Check for the right number and sort of divisional markers.



