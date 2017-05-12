use Test::More tests => 4;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {
        one => {
            label     => 'Object',
            max_alpha => 2
        }
    }
);

$r->params->{one} = 'a';
ok $r->validate('one'), 'validation ok';

$r->params->{one} = 'be';
ok $r->validate('one'), 'validation ok';

$r->params->{one} = 'see';
ok !$r->validate('one'), 'validation failed';

$r->params->{one} = 123456;
ok $r->validate('one'), 'validation ok';
