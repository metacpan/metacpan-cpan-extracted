use Test::More tests => 3;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {foobar => {max_length => 5}},
    params => {foobar => 'apple'}
);

ok $r->validate(), 'foobar validates';
$r->fields->{foobar}->{max_length} = 4;

ok !$r->validate(), 'foobar doesnt validate';
ok $r->errors_to_string() =~ /must not contain more than 4/,
  'displays proper error message';

#warn $r->errors_to_string();
