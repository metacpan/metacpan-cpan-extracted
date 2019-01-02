use strict;
use warnings;

use Test::More;
use Variable::Declaration;

use Type::Nano qw(Int);

subtest 'SCALAR' => sub {
    Variable::Declaration::type_tie(my $i, Int, 123);

    my $t = tied($i);
    ok $t && $t->isa('Type::Tie::SCALAR'), 'tied Type::Tie::SCALAR';
    is $i, 123, 'value is 123';

    eval {
        $i = {};
    };
    like $@, qr/did not pass type constraint Int/, 'cannot assign';
};

subtest 'ARRAY' => sub {
    Variable::Declaration::type_tie(my @a, Int, 123, 456);

    my $t = tied(@a);
    ok $t && $t->isa('Type::Tie::ARRAY'), 'tied Type::Tie::ARRAY';
    is_deeply \@a, [123,456], 'value is [123, 456]';

    eval {
        @a = {};
    };
    like $@, qr/did not pass type constraint Int/, 'cannot assign';
};

subtest 'HASH' => sub {
    Variable::Declaration::type_tie(my %h, Int, 'key' => 123);

    my $t = tied(%h);
    ok $t && $t->isa('Type::Tie::HASH'), 'tied Type::Tie::HASH';
    is_deeply \%h, {key => 123}, 'value is {key => 123}';

    eval {
        %h = (key => 'hello');
    };
    like $@, qr/did not pass type constraint Int/, 'cannot assign';
};

done_testing;
