#!perl -T
#
# $Id: 02-lazier-basic.t,v 0.1 2007/05/26 17:54:19 dankogai Exp $
#
use strict;
use warnings;
use Tie::Array::Lazier;

use Test::More tests => 3;

tie my @a, 'Tie::Array::Lazier', [], sub { $_[1] };
ok tied @a, 'tied @a';
is $a[3], 3, '$a[3] == 3';
is_deeply(
    ( tied @a )->array,
    [ undef, undef, undef, 3 ],
    '[undef,undef,undef,3]'
);
