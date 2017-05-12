#!perl -T

use Test::More tests => 6;
use WWW::Scraper::ISBN;

BEGIN {
	use_ok( 'WWW::Scraper::ISBN::AmazonDE_Driver' );
}

my $isbn = '3473580082';
my $scraper = WWW::Scraper::ISBN->new;
   $scraper->drivers("AmazonDE");

my $record = $scraper->search( $isbn );

ok( $record->found );
my $book = $record->book;

my @months = qw(Januar Februar März April Mai Juni Juli August September Oktober November Dezember);
my $regex = join '|', @months;

is( $book->{title}, 'Die Welle' );
like( $book->{author}, qr/Morton Rhue,\s*Hans-Georg Noack/ );
is( $book->{publisher}, 'Ravensburger Buchverlag' );
like( $book->{pubdate}, qr/(?:$regex) (?:19|20)\d\d/ );

