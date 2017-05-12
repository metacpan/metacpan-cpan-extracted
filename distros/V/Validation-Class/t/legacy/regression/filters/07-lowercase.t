use Test::More tests => 1;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'lowercase'}},
    params => {foobar => '123ABC456DEF'}
);

ok $v->params->{foobar} =~ /^123abc456def$/,
  'lowercase filter working as expected';
