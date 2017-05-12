#!/usr/bin/perl -w
use strict;

use lib qw(lib);

use Data::Dumper;
use Getopt::Long;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER = 'Wheelers';

my @fields = qw(isbn13 isbn10 author title width height depth weight publisher pubdate binding pages thumb_link image_link book_link);

###########################################################

my $scraper = WWW::Scraper::ISBN->new();
$scraper->drivers($DRIVER);

my %options;
GetOptions(
    \%options,
    'raw|r',
    'detail|d'
) or die "Usage: $0 [--raw | --detail] <isbn> ...\n";

for my $isbn (@ARGV) {
    my $record = $scraper->search($isbn);

    if($options{raw}) {
        unless($record->found) {
            print "$isbn: error=[".Dumper($record)."]\n";
        } else {
            my $book = $record->book;
            print "$isbn: book=[".Dumper($book)."]\n";
        }

    } elsif($options{detail}) {
        unless($record->found) {
            print "$isbn: error=[".$record->error()."]\n";
        } else {
            my $book = $record->book;
            print "$isbn:\n";
            printf "- %10s = %s\n", $_, (defined $book->{$_} ? $book->{$_} : '') for(@fields);
            print "-" x 10 . "\n";
        }

    } else {
        unless($record->found) {
            print "$isbn: NOT FOUND\n";
        } else {
            print "$isbn: FOUND\n";
        }
        
    }
}

###########################################################
