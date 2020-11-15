################################################################################
#
# Copyright (c) 2002-2016 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;

BEGIN { plan tests => 12 };

use Tie::Hash::Indexed;
ok(1);

tie %h, 'Tie::Hash::Indexed';
ok(1);

###----------------------------------------------------------------------------
###  BUG: Deleting hash values while iterating caused segfaults or panics
###
###  Bug spotted by Cristian Cocheci
###----------------------------------------------------------------------------

%h = (
  mhx => 1,
  abc => 2,
  foo => 3,
  bar => 4,
);

ok(scalar keys %h, 4);

$i = 1;

while (my($key, $val) = each %h) {
  my $v = delete $h{$key};
  ok($v, $val);
  ok($v, $i++);
}

ok(scalar keys %h, 0);
