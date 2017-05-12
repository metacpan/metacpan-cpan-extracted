use Test::More tests => 5;

package MyVal;

use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {
        foobar => {
            error      => 'foobar error',
            validation => sub {
                shift->{_ran_}++;
                return 1;
              }
        },
        barfoo => {
            required   => 1,
            validation => sub {
                return 0;
              }
        }
    },
    params => {
        foobar => 'abc123456',
        barfoo => 1
    }
);

ok $v, 'class initialized';
ok $v->validate('foobar'), 'valid';
ok $v->{_ran_} == 1, 'validation ran once as intended';
ok !$v->validate('barfoo'), 'not valid';
ok $v->errors_to_string, 'error message';
