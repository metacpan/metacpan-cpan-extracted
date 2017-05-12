use Test::More tests => 1;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'strip'}},
    params => {
        foobar => '   the quick  brown     fox jumped   over the           ...'
    }
);

ok $v->params->{foobar} =~ /^the quick brown fox jumped over the ...$/,
  'strip filter working as expected';
