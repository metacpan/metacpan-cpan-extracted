use Test::More tests => 3;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'numeric'}},
    params => {foobar => '123abc456def'}
);

ok $v->params->{foobar} =~ /^123456$/, 'numeric filter working as expected';

$v = MyVal->new(
    fields => {foobar => {filters => 'numeric'}},
    params => {foobar => '----     123abc456def'}
);

ok $v->params->{foobar} =~ /^-123456$/, 'numeric filter working with negative number as expected';

$v = MyVal->new(
    fields => {foobar => {filters => 'numeric'}},
    params => {foobar => '     - ----     123abc456def'}
);

ok $v->params->{foobar} =~ /^-123456$/, 'numeric filter working with negative number as expected';
