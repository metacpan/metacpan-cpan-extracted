use strict;
use warnings;
use Test::More tests => 8;

use JSON::Syck;

{    # Impossible circular blessed references in JSON
    my $foo = bless {}, "Foo";
    my $bar = bless { foo => $foo }, "Bar";
    $foo->{bar} = $bar;

    my $result = eval { JSON::Syck::Dump($foo) };
    is( $result, undef, "A Structure should come back on a JSON dump with circular blessed references" );
    like( $@, qr/^Dumping circular structures is not supported with JSON::Syck/, "Die is thrown when the circular blessed ref happens" );
}

{    # Circular references broken regardless of blessing
    my $foo = {};
    my $bar = { foo => $foo };
    $foo->{bar} = $bar;

    my $result = eval { JSON::Syck::Dump($foo) };
    is( $result, undef, "A Structure should come back on a JSON dump with duplicate references" );
    like( $@, qr/^Dumping circular structures is not supported with JSON::Syck/, "Die is thrown when the circular ref happens" );
}

{
    my $foo = {};

    my $result = eval { JSON::Syck::Dump( [ $foo, $foo ] ) };
    is( $result, '[{},{}]', "A Structure should come back on a JSON dump with duplicate references" );
    is( $@,      '',        "No die is thrown when the circular ref happens" );
}

{
    my $foo = { 'a' => [ 1, 2 ] };

    my $result = eval { JSON::Syck::Dump( [ $foo, $foo ] ) };
    is( $result, '[{"a":[1,2]},{"a":[1,2]}]', "A Complex structure should come back on a JSON dump with duplicate references" );
    is( $@, '', "No die is thrown when the circular ref happens" );
}

