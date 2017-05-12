use Test::More tests => 1;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'alpha'}},
    params => {foobar => 'acb123def456xyz'}
);

ok $v->params->{foobar} =~ /^acbdefxyz$/, 'alpha filter working as expected';
