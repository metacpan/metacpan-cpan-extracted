#!perl -T
#
# $Id: 03-ops.t,v 0.1 2007/05/26 17:54:19 dankogai Exp $
#
use strict;
use warnings;
use Tie::Array::Lazy;

#use Test::More tests => 14;
use Test::More 'no_plan';

for my $mod (qw/Tie::Array::Lazy Tie::Array::Lazier/){
    tie my @a, 'Tie::Array::Lazy', [], sub { $_[0]->index };
    push    @a, 2,3;
    unshift @a, 0,1;
    is_deeply( ( tied @a )->array, [ 0, 1, 2, 3 ]);
    is ((pop   @a), 3);
    is ((shift @a), 0);
    is_deeply ([splice @a,0,2], [1,2]);
    is ((pop   @a), 0);
    is ((shift @a), 0);
    is_deeply ([splice @a,1,2], [1,2]);
}
