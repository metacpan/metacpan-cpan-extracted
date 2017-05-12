use Test::More tests => 2;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'currency'}},
    params => {foobar => '$2,000,000.99'}
);

ok $v->params->{foobar} =~ /^2,000,000\.99$/, 'currency filter working as expected';

$v = MyVal->new(
    fields => {foobar => {filters => 'currency'}},
    params => {foobar => ' -- - - $ 2,000,000.99'}
);

ok $v->params->{foobar} =~ /^-2,000,000\.99$/, 'currency filter working with negative number as expected';
