use Test::More tests => 2;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'decimal'}},
    params => {foobar => '$2000.99'}
);

ok $v->params->{foobar} =~ /^2000\.99$/, 'decimal filter working as expected';

$v = MyVal->new(
    fields => {foobar => {filters => 'decimal'}},
    params => {foobar => '- $2000.99'}
);

ok $v->params->{foobar} =~ /^-2000\.99$/, 'decimal filter working with negative number as expected';
