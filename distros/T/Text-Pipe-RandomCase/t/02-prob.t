use strict;
use warnings;
use Test::More;
use Text::Pipe;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test. Those tests could fail due probability.';
    plan( skip_all => $msg );
} else {
	plan tests => 2;
}

my ($input,$output,$counter);

my $pipe = Text::Pipe->new('RandomCase');

$input = 'foobar' x 40;

$pipe->probability(2);

$output = $pipe->filter($input);

ok( $output =~ /[a-z]/ && $output =~ /[A-Z]/, 'long string has lower and upper case characters (frequency 2)');

$input = "foobar";
$pipe->probability(10000);
$pipe->set_force_one;
$counter = 0;

for (my $i=0;$i<100;$i++) {
	my $count = ($input =~ tr/[[:upper:]]//);
	$counter++ if $count == 1;
}
	
ok($counter > 97,'force_one with low probalitity of uppercased produced one uppercased');

