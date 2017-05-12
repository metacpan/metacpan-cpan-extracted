use strict;
use warnings;

use Test::More;

use Valiemon;

use_ok 'Valiemon::Attributes::Enum';

subtest 'validate enum' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        enum => [1, 2, 4],
    });

    ($res, $err) = $v->validate(1);
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate(4);
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate(0);
    ok !$res;
    is $err->position, '/enum';

    ($res, $err) = $v->validate('three');
    ok !$res;
    is $err->position, '/enum';
};

subtest 'validate enum multi types' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        enum => [2, 4, 'two', 'four', [ 2, 4 ], { 2 => 4 }],
    });

    ($res, $err) = $v->validate(2);
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate('four');
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({ 2 => 4 });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate([4, 2]);
    ok !$res;
    is $err->position, '/enum';

    ($res, $err) = $v->validate({ 2 => "5" });
    ok !$res;
    is $err->position, '/enum';

    TODO : {
        local $TODO = 'strict type check';
        ($res, $err) = $v->validate({ 2 => "4" });
        ok !$res;
        # is $err->position, '/enum';
    }
};

subtest 'validate enum in object' => sub {
    my ($res, $err);
    my $v = Valiemon->new({
        type => 'object',
        properties => {
            name => { type => 'string' },
            sex => { enum => [qw(male fimale other)] },
            region => { enum => [qw(jp us eu)] },
        },
        required => [qw(sex region)],
    });

    ($res, $err) = $v->validate({
        name => 'poku',
        sex => 'male',
        region => 'eu',
    });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({
        sex => 'other',
        region => 'jp',
    });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({
        sex => 'alien',
        region => 'jp',
    });
    ok !$res;
    is $err->position, '/properties/sex/enum';

    ($res, $err) = $v->validate({
        sex => 'male',
        region => [qw(jp eu)],
    });
    ok !$res;
    is $err->position, '/properties/region/enum';

};


done_testing;
