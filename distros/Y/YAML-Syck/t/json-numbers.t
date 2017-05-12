use Test::More tests => 53;

use JSON::Syck qw(Dump);

my @arr1 = sort { $a cmp $b } qw/1 2 54 howdy/;
is( Dump( \@arr1 ), '["1","2","54","howdy"]', "cmp sort causes numbers to coerce into strings and thus be quoted." );

{
    no warnings "numeric";
    my @arr2 = sort { $a <=> $b } qw/1 2 54 howdy/;
    is( Dump( \@arr2 ), '["howdy","1","2","54"]', "Numeric sort doesn't coerce non-numeric strings into numbers because they still contain their valid string" );
}

my @arr54 = ( "howdy", 1, 2, 54 );
is( Dump( \@arr54 ), '["howdy",1,2,54]', "Strings are quoted. Numbers are not" );

is( Dump('042'),       '"042"',       "Ocatls don't get treated as numbers" );
is( Dump('0x42'),      '"0x42"',      "Hex doesn't get treated as a number" );
is( Dump('0.42'),      '"0.42"',      "Floats with leading 0 don't get excluded by octal check" );
is( Dump('1_000_000'), '"1_000_000"', "numbers with underscores get quoted." );
is( Dump('1,000,000'), '"1,000,000"', "numbers with commas get quoted." );
is( Dump('1e+6'),      '"1e+6"',      "Scientific notation gets quoted." );
is( Dump('10e+6'),     '"10e+6"',     "Scientific notation gets quoted." );
is( Dump('0123'),      '"0123"',      "Scientific notation gets quoted." );

# for simple integers, we need to preserve their string state as perl knows it if possible.
# JSON overloaded + for string concatenation. This means you get all sorts of wierdness if we try to strip quotes on strings not IVs
# "0" is true 0 is false. 1 + 1 = 2 but "1" + "1" = "11"
for ( -10 .. 10 ) {
    is( Dump($_),   $_,       '"0" != 0 in JSON. 0 is false "0" is true.' );
    is( Dump("$_"), "\"$_\"", 'Strigified integer is stringified in JSON' );
}
