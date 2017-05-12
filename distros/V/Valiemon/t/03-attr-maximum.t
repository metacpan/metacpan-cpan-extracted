use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::Maximum';

subtest 'maximum' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        type => 'integer',
        maximum => 3,
    });
    ($res, $err) = $v->validate(2);
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate(3);
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate(4);
    ok !$res;
    is $err->position, '/maximum';
};

subtest 'maximum with exclusiveMaximum' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        type => 'integer',
        maximum => 3,
        exclusiveMaximum => 1,
    });
    ($res, $err) = $v->validate(2);
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate(3);
    ok !$res;
    is $err->position, '/maximum';

    ($res, $err) = $v->validate(4);
    ok !$res;
    is $err->position, '/maximum';
};

done_testing;
