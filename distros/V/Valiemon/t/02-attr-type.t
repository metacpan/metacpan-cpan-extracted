use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::Type';

subtest 'validate type object' => sub {
    my ($res, $err);
    my $v = Valiemon->new({ type => 'object' });
    ($res, $err) = $v->validate({});
    ok $res, 'object is valid!';
    is $err, undef;

    ($res, $err) = $v->validate('hello');
    ok !$res, 'string is invalid';
    is $err->position, '/type';

    ($res, $err) = $v->validate([]);
    ok !$res, 'array is invalid';
    is $err->position, '/type';

    ($res, $err) = $v->validate(120);
    ok !$res, 'integer is invalid';
    is $err->position, '/type';

    ($res, $err) = $v->validate(5.5);
    ok !$res, 'number is invalid';
    is $err->position, '/type';

    ($res, $err) = $v->validate(undef);
    ok !$res, 'null is invalid';
    is $err->position, '/type';

    ($res, $err) = $v->validate(1);
    ok !$res, 'boolean is invalid';
    is $err->position, '/type';
};

done_testing;
