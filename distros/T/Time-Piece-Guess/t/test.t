#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Time::Piece;

BEGIN {
    use_ok( 'Time::Piece::Guess' ) || print "Bail out!\n";
}

my $tests_ran = 1;


# make sure it works with a known good file
my $worked = 0;
$tests_ran++;
eval {
    my $string='2023-02-27T11:00:18';
    my ($format, $ms_clean_regex) = Time::Piece::Guess->guess($string);
    if (defined( $ms_clean_regex )){
		die('Got a microsecond removal regexp unexpectedly');
    }

	$string='2023-03-12T10:07:19.33+1010';
    ($format, $ms_clean_regex) = Time::Piece::Guess->guess($string);
    if (!defined( $ms_clean_regex )){
		die('Did not get a microsecond removal regexp to use');
    }
	$string=~s/$ms_clean_regex//;

    my $tp_object;
    if (!defined( $format )){
		die('Failed to match a known good timestamp');
    }else{
        $tp_object = Time::Piece->strptime( $string , $format );
		if (!defined($tp_object)) {
			die('Failed to create a Time::Piece object using the returned format');
		}
    }

	my $obj=Time::Piece::Guess->guess_to_object($string);
	if ($@) {
		die('Died calling guess_to_object... '.$@);
	}
	if (!defined($obj)) {
		die('Returned undef from guess_to_object');
	}

	$worked=1;
};
ok( $worked eq '1', 'run some basic tests' ) or diag( $@ );


plan tests => $tests_ran;
done_testing($tests_ran);

