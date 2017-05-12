use Test::More tests => 5;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {
        two => {
            label    => 'The Two',
            required => 1
        },
        one => {
            label      => 'The One',
            depends_on => 'two'
        }
    }
);

ok $r->validate('one'), 'one not required, pass';

$r->params->{one} = 1;    # flag

ok !$r->validate('one'), 'two is required';
ok $r->error_count == 1, 'error count ok';

$r->params->{two} = 2;

ok $r->validate('one'), 'validation ok';
ok !$r->error_count, 'error count ok';
