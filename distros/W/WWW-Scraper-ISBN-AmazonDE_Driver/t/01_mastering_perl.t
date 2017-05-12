#!perl -T

use Test::More tests => 6;
use WWW::Scraper::ISBN;

BEGIN {
	use_ok( 'WWW::Scraper::ISBN::AmazonDE_Driver' );
}

my $isbn = '0-596-52724-1';
my $scraper = WWW::Scraper::ISBN->new;
   $scraper->drivers("AmazonDE");

my $record = $scraper->search( $isbn );

ok( $record->found );
my $book = $record->book;

my @months = qw(Januar Februar März April Mai Juni Juli August September Oktober November Dezember);
my $regex = join '|', @months;

is( $book->{title}, 'Mastering Perl' );
is( $book->{author}, 'Brian D. Foy' );
is( $book->{publisher}, 'O\'Reilly Media' );
like( $book->{pubdate}, qr/(?:$regex) 20\d\d/ );
