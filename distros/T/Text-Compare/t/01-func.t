use Test::More tests => 5;

use File::Spec::Functions;
use lib catdir ('..', 'lib');

BEGIN {
	use_ok( 'Text::Compare' );
}

no warnings; # Skip warnings from Text::German::Endung
$SIG{'WARN'} = sub {};

my $string1 = "Hallo Welt, was fuer ein schoener Tag heute";
my $string2 = "Hallo Welt, was fuer ein schrecklicher Tag heute";

my $tc = new Text::Compare;

$tc->first($string1);
$tc->second($string2);

ok($tc->similarity() eq '0.8', 'First call');
ok($tc->similarity() eq '0.8', 'Second call');

my $tc2 = new Text::Compare;

my $list1 = $tc2->get_words($string1);
my $list2 = $tc2->get_words($string2);

$tc2->first_list($list1);
$tc2->second_list($list2);

ok($tc2->similarity() eq '0.8', 'Third call');
ok($tc2->similarity() eq '0.8', 'Fourth call');

