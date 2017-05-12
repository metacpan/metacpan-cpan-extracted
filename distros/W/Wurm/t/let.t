#!perl

use strict;
use warnings;

use Test::More;
use Wurm::let;


my $grub = Wurm::let->new;
isa_ok($grub, 'Wurm::let');

my $bulk = $grub->molt;
is(ref $bulk, 'HASH', 'auto bulk');

is(Wurm::let->new($bulk)->molt, $bulk, 'bulk pass-through');

for my $method (qw(case pore gate neck tail)) {
  $grub->$method(sub{$method});
  is($bulk->{$method}->(), $method, 'Wurm::let->'. $method. '()');
}

for my $method (qw(get head post put delete trace options connect patch)) {
  $grub->$method(sub{$method});
  is($bulk->{body}{$method}->(), $method, 'Wurm::let->'. $method. '()');
}

$grub->body(foo           => sub {'qux'});
$grub->body([qw(bar baz)] => sub {'qux'});
is($bulk->{body}{$_}->(), 'qux', 'Wurm::let->body()')
  for qw(foo bar baz);

$grub->tube(foo => $bulk);
is($bulk->{tube}{foo}, $bulk, 'Wurm::let->tube()');

$grub->grub(bar => $bulk);
is($bulk->{tube}{bar}, $bulk, 'Wurm::let->grub()');

done_testing();
