#!perl -T
#
# $Id: 01-lazy-basic.t,v 0.1 2007/05/26 17:54:19 dankogai Exp $
#
use strict;
use warnings;
use Tie::Array::Lazy;

use Test::More tests => 3;

tie my @a, 'Tie::Array::Lazy', [], sub { $_[0]->index };
ok tied @a, 'tied @a';
is $a[3], 3, '$a[3] == 3';
is_deeply( ( tied @a )->array, [ 0, 1, 2, 3 ], '[0,1,2,3]' );
