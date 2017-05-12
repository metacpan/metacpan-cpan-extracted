use Test::More tests => 1;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'capitalize'}},
    params => {
        foobar =>
          'i am that I am. this is not going to work. im leaving, good bye.'
    }
);

ok $v->params->{foobar}
  =~ /^I am that I am. This is not going to work. Im leaving, good bye./,
  'capitalize filter working as expected';
