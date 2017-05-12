use Test::More tests => 1;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {
        status => {

            # ...
        }
    },
    params => {
        _dc => '1310548813350',
        id  => 'i4jiojtrgijeriogjrtiorjwgoitjr'
    },
    ignore_unknown => 1
);

# resolve the anomyly
ok $r->validate('_foo'), 'valid by default';
