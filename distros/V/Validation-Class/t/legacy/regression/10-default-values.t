use Test::More;

package MyVal::A;

use Validation::Class;

package MyVal::B;

use Validation::Class;

mixin ':unique' => {
    pattern    => qr/^\d+$/,
    required   => 1,
    min_length => 1,
    max_length => 255,
    filters    => ['trim', 'strip', 'numeric'],
    default    => sub { time() }
};

package main;

my $a = MyVal::A->new(
    fields => {
        access_key  => {
            default  => 12345,
            required => 1
        },
        access_code => {
            default => sub {
                return ref shift;
            },
            required => 1
        },
    },
    params => {
        access_key  => 'abcde',
        access_code => 'abcdefghi'
    }
);

ok $a, 'class initialized';

ok 'abcde' eq $a->params->get('access_key'), 'access_key has explicit value';
ok 'abcdefghi' eq $a->params->get('access_code'), 'access_code has explicit value';

$a->params->clear;

ok $a->validate('access_code', 'access_key'), 'params validated via default values';

ok 12345 eq $a->params->get('access_key'), 'access_key has default value';
ok 'MyVal::A' eq $a->params->get('access_code'), 'access_code has default value w/context';

my $b = MyVal::B->new(
    fields => {
        access_code => {
            mixin   => ':unique',
            multiples => 1,
            default => sub { time() },
            required => 1
        },
    },
    params => {
    }
);

ok $b->validate('access_code'), 'access_code passed validation';

#require Data::Dumper; die Data::Dumper::Dumper($b->proto->fields, $b->proto->params);

done_testing;
