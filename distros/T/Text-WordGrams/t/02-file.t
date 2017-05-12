#!perl -T

use Test::More tests => 11;
use Text::WordGrams;

my $data = word_grams_from_files( "t/02-input" );

is(ref($data), "HASH");

is($data->{"ante ."}, 2);
is($data->{"Etiam velit"}, 1);
is($data->{"leo ."}, 6);
is($data->{"ridiculus"}, undef, "testing 'ridiculus'");


$data = word_grams_from_files( "t/02-input", "t/02-input" );
is($data->{"ante ."}, 4);
is($data->{"Etiam velit"}, 2);
is($data->{"leo ."}, 12);
is($data->{"ridiculus"}, undef, "testing 'ridiculus'");

$data = word_grams_from_files( {size=>4}, "t/02-input" );

is($data->{"Lorem ipsum dolor sit"}, 2);
is($data->{"Sed convallis urna vel"}, 1);
