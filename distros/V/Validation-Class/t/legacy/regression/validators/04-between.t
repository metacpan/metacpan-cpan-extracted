use Test::More tests => 3;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {foobar => {between => '2-5'}},
    params => {foobar => 'apple'}
);

ok $r->validate(), 'foobar validates';
$r->params->{foobar} = '#';

ok !$r->validate(), 'foobar doesnt validate';
ok 'foobar must contain between 2-5 characters' eq $r->errors_to_string(),
  'displays proper error message';

#warn $r->errors_to_string();
