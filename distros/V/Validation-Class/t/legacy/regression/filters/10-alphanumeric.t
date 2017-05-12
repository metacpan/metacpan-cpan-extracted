use Test::More tests => 1;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'alphanumeric'}},
    params => {foobar => '1@%23abc45@%#@#%6d666ef..'}
);

ok $v->params->{foobar} =~ /^123abc456d666ef$/,
  'alphanumeric filter working as expected';
