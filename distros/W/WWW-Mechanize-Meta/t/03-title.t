#!perl
#use Test::More skip_all => 'Bug with encoding was not fixed';
use Test::More tests => 3;
use utf8;

BEGIN {
	use_ok( 'WWW::Mechanize::Meta' );
	use_ok( 'Data::Dumper' );
}
my $mech=WWW::Mechanize::Meta->new();
$mech->get('http://bash.org.ru');
is($mech->title,'bash.org.ru - Цитатник Рунета');

