# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Time::Stamp';
eval "require $mod" or die $@;

# Test that subs have been defined in the package (__PACKAGE__->import)

my @subs = (
  [localstamp => []],
  [gmstamp => []],
  [parselocal => ['2011-03-02T11:12:13']],
  [parsegm    => ['2011-03-02T11:12:13Z']],
);

plan tests => 1 + scalar @subs;

{
  no strict 'refs';
  is(eval { &{"${mod}::_undef_sub"}(); 1 }, undef, 'sanity check');
}

foreach my $sub ( @subs ){
  my ($name, $args) = @$sub;
  no strict 'refs';
  ok(eval { &{"${mod}::${name}"}(@$args) }, "have ${mod}::${name}()");
}
