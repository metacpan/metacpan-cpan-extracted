use strict;
use warnings;
use Text::KyTea;
use Test::More;
use Test::Fatal;
use Test::Warn;

can_ok('Text::KyTea', qw/new parse read_model pron/);

subtest 'new method' => sub {
    my $kytea;
    is( exception{ $kytea = Text::KyTea->new;                                 }, undef, 'model: default'          );
    is( exception{ $kytea = Text::KyTea->new(model => './model/test.mod')     }, undef, 'model: ./model/test.mod' );
    is( exception{ $kytea = Text::KyTea->new({ model => './model/test.mod' }) }, undef, 'model: ./model/test.mod (hashref)' );
    isa_ok($kytea, 'Text::KyTea');

    like( exception{ $kytea = Text::KyTea->new(model => 'のっふぁん') }, qr/^model file not found/,  'model: not found' );
    like( exception{ $kytea = Text::KyTea->new(h2z   => 1)            }, qr/^Unknown option: 'h2z'/, 'unknown option'   );
};

subtest 'read_model method' => sub {
    my $kytea = Text::KyTea->new(model => './model/test.mod');
    is( exception{ $kytea->read_model('./model/test.mod') }, undef, 'read_model' );
};

subtest 'parse method' => sub {
    my $kytea = Text::KyTea->new(model => './model/test.mod');

    my $results;
    is( exception { $results = $kytea->parse("コーパスの文です。") }, undef, 'parse normal string' );
    cmp_ok(scalar @{$results}, '>', 0, 'result of parsing normal string');
    parse_test($results);

    is( exception { $results = $kytea->parse("") }, undef, 'parse empty string' );
    is(scalar @{$results}, 0, 'result of parsing emtry string');

    warning_like { $results = $kytea->parse(undef) } qr/uninitialized value/, 'parse undefined string';
    is(scalar @{$results}, 0, 'result of parsing undefined string');

    is( exception { $results = $kytea->parse(0) }, undef, 'parse zero' );
    is(scalar @{$results}, 1, 'result of parsing zero');
};

subtest 'pron method' => sub {
    my $kytea = Text::KyTea->new(model => './model/test.mod');

    my $pron;

    is( exception { $pron = $kytea->pron("コーパスの文です。") }, undef, 'pron of normal string' );
    is($pron, 'こーぱすのぶんです。');

    is( exception { $pron = $kytea->pron("") }, undef, 'pron of emtry string' );
    is($pron, '');

    warning_like { $pron = $kytea->pron(undef) } qr/uninitialized value/, 'pron of undefined string';
    is($pron, '');

    is( exception { $pron = $kytea->pron(0) }, undef, 'pron of zero' );
    isnt($pron, '');
};


done_testing;


sub parse_test
{
    my $results = shift;

    for my $result (@{$results})
    {
        unlike($result->{surface}, qr/[0-9\.\-]/);

        for my $tags (@{$result->{tags}})
        {
            for my $tag (@{$tags})
            {
                unlike($tag->{feature}, qr/[0-9\.\-]/);
                like($tag->{score}, qr/^[0-9\.\-]+$/);
            }
        }
    }
}
