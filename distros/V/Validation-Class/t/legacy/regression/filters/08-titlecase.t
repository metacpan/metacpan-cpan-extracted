use Test::More tests => 1;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'titlecase'}},
    params => {foobar => 'mr. frank white'}
);

ok $v->params->{foobar} =~ /^Mr\. Frank White$/,
  'titlecase filter working as expected';
