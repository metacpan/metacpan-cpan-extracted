use Test::More tests => 3;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {foobar => {between => '2-5'}},
    params => {foobar => 3}
);

ok $r->validate(), 'foobar validates';
$r->params->{foobar} = 8;

ok !$r->validate(), 'foobar doesnt validate';
ok 'foobar must be between 2-5' eq $r->errors_to_string(),
  'displays proper error message';

#warn $r->errors_to_string();
