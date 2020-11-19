################################################################################
#
# Copyright (c) Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;

BEGIN { plan tests => 10 };

use Tie::Hash::Indexed;
ok(1);

tie my $c, 'MagicScalar', 42;

ok($MagicScalar::GLOBAL, 42);
ok($c, 42);
$c = 13;
ok($MagicScalar::GLOBAL, 13);
ok($c, 13);

my $h = Tie::Hash::Indexed->new(foo => 1, bar => 2, zoo => 3, baz => 4);

$h->set('foo', $c);
ok($h->get('foo'), 13);

$h->add('foo', ++$c);
ok($h->get('foo'), 27);

my %h2;
$h2{foo} = $c;
ok($h2{foo}, 14);

$c++;
ok($h2{foo}, 14);

tie $h2{foo}, 'MagicScalar';
ok($h2{foo}, 15);

package MagicScalar;

use vars qw( $GLOBAL );

sub TIESCALAR { $GLOBAL = $_[1] if @_ > 1; bless [], $_[0] }
sub FETCH { $GLOBAL }
sub STORE { $GLOBAL = $_[1] }

