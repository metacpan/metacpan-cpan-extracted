use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use autobox::Core;

use lib "lib";
use autobox::Transform;

subtest "array_to_ref" => sub {
    my $array = [ 1, 2 ];
    my @array = @$array;
    eq_or_diff(
        [ @array->to_ref ],
        [ $array ],
        "Array to_ref in list context works",
    );
    eq_or_diff(
        [ $array->to_ref ],
        [ $array ],
        "ArrayRef to_ref in list context works",
    );
};

subtest "hash_to_ref" => sub {
    my $hash = { 1 => 2, 2 => 3 };
    my %hash = %$hash;
    eq_or_diff(
        [ %hash->to_ref ],
        [ $hash ],
        "Hash to_ref in list context works",
    );
    eq_or_diff(
        [ $hash->to_ref ],
        [ $hash ],
        "HashRef to_ref in list context works",
    );
};

subtest "array_to_array" => sub {
    my $array = [ 1, 2 ];
    my @array = @$array;
    eq_or_diff(
        [ @array->to_array ],
        [ @array ],
        "Array to_array in list context works",
    );
    eq_or_diff(
        [ $array->to_array ],
        [ @array ],
        "ArrayRef to_array in list context works",
    );
};

subtest "array_to_hash" => sub {
    my $array = [ 1, 2 ];
    my @array = @$array;
    eq_or_diff(
        @array->to_hash->to_ref,
        { 1 => 2 },
        "Array to_hash works",
    );

    throws_ok(
        sub { [ 1, 2, "c" ]->to_hash },
        qr/\@array->to_hash on an array with an odd number of elements \(3\) at/,
        "Array to_hash with an odd number of items goes *boom*",
    );
};

subtest "hash_to_hash" => sub {
    my $hash = { a => 1, b => 2 };
    my %hash = %$hash;
    eq_or_diff(
        { %hash->to_hash },
        { %hash },
        "Hash to_hash in list context works",
    );
    eq_or_diff(
        { $hash->to_hash },
        { %hash },
        "HashRef to_hash in list context works",
    );
};

subtest "hash_to_array" => sub {
    my $hash = { z => 1, a => 1, b => 2 };
    eq_or_diff(
        [ $hash->to_array ],
        [ a => 1, b => 2, z => 1 ],
        "Hash to_array works",
    );
};


done_testing();
