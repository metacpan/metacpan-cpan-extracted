use Test::More tests => 5;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {foobar => {length => '1'}},
    params => {foobar => 'a'}
);

ok $r->validate(), 'foobar validates';
$r->params->{foobar} = 'abc';

ok !$r->validate(), 'foobar doesnt validate';
ok $r->errors_to_string()
  =~ /should be exactly 1 characters/,
  'displays proper error message';

$r->params->{foobar} = 'a';
$r->fields->{foobar}->{length} = 2;

ok !$r->validate(), 'foobar doesnt validate';
ok $r->errors_to_string()
  =~ /should be exactly 2 characters/,
  'displays proper error message';

#warn $r->errors_to_string();
