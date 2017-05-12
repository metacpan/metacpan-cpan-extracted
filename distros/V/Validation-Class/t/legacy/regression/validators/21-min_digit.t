use Test::More tests => 4;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {
        one => {
            label      => 'Object',
            min_digits => 2
        }
    }
);

$r->params->{one} = 111;
ok $r->validate('one'), 'validation ok';

$r->params->{one} = 11;
ok $r->validate('one'), 'validation ok';

$r->params->{one} = 1;
ok !$r->validate('one'), 'validation failed';

$r->params->{one} = '11abcdef';
ok $r->validate('one'), 'validation ok';
