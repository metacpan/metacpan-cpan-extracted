use Test::More tests => 7;

package MyVal;

use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {
        foobar => {
            validation => sub {
                shift->stash->{foo};
              }
        }
    }
);

ok $v, 'class initialized';
ok $v->stash(foo => 'bar'), 'stash key foo set';
ok $v->stash('foo') eq 'bar', 'stash value bar set';
ok $v->stash({baz => 'xyz'}), 'stash key baz set';
ok $v->stash('baz') eq 'xyz', 'stash value xyz set';
ok 2 == keys %{$v->stash}, 'stash hash access and keys validated';
ok $v->validate('foobar'), 'stash accessible from custom val-routine';
