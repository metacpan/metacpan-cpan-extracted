#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use re::engine::Hooks;

for my $key ('foo bar', 'foo-bar', 'foo!', 'bar?') {
 local $@;
 eval {
  re::engine::Hooks::enable($key);
 };
 like $@, qr/^Invalid key /, "$key is not a valid key";
}
