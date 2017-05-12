use strict;
use warnings;

use Test::More;
use Test::Stub::Generator qw(make_method);

package Some::Class;
sub new { bless {}, shift }
sub increment;

package main;

subtest "single" => sub {
    my $method = make_method { expects => [0], return => 1 };
    my $obj = Some::Class->new;
    *Some::Class::increment = $method;
    is( $obj->increment(0), 1, 'sub return are as You expected' );
};

subtest "multi" => sub {
    my $method = make_method(
        [
            { expects => [0], return => 1 },
            { expects => [1], return => 2 },
        ]
    );

    my $obj = Some::Class->new;
    *Some::Class::increment = $method;

    is( $obj->increment(0), 1, 'sub return are as You expected' );
    is( $obj->increment(1), 2, 'sub return are as You expected' );
};


done_testing;
