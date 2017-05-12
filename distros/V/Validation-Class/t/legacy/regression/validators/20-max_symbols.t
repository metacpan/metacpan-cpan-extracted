use Test::More tests => 4;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {
        one => {
            label       => 'Object',
            max_symbols => 2
        }
    }
);

$r->params->{one} = '@';
ok $r->validate('one'), 'validation ok';

$r->params->{one} = '@@';
ok $r->validate('one'), 'validation ok';

$r->params->{one} = '@@#';
ok !$r->validate('one'), 'validation failed';

$r->params->{one} = '$$D';
ok $r->validate('one'), 'validation ok';
