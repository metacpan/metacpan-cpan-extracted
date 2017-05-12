#!/usr/bin/perl -w

#=============================================================================
#
# $Id: reverse.t,v 0.03 2001/11/16 02:31:30 mneylon Exp $
# $Revision: 0.03 $
# $Author: mneylon $
# $Date: 2001/11/16 02:31:30 $
# $Log: reverse.t,v $
# Revision 0.03  2001/11/16 02:31:30  mneylon
# Updating to fix version problems
#
# Revision 0.02  2001/11/16 02:21:31  mneylon
# Update to version 0.02
#
# Revision 0.01.01.1  2001/11/15 01:43:52  mneylon
# Branch for 0.01 changes
#
# Revision 0.01  2001/11/11 18:40:57  mneylon
# Initial release
#
#
#=============================================================================

# Reverse iterator testing

use strict;
use Tie::Array::Iterable;

use Test::More tests => 62;

my @array = ( 0 .. 10 );

my $iterarray = new Tie::Array::Iterable( @array );

my $iter = $iterarray->from_end();

is( $iter->value(),	10,	"Reverse, value from start" );
is( $iter->index(),	11,	"Reverse, index from start" );
ok( $iter->at_start(),	"Reverse, at start" );

$iter->prev();  # Should go nowhere

is( $iter->value(),	10,	"Reverse, prev value from start" );
is( $iter->index(), 11,	"Reverse, prev index from start" );
ok( $iter->at_start(),	"Reverse, at start with prev" );

$iter->next();  # now go to 9

is( $iter->value(),	9,	"Reverse, next value from start" );
is( $iter->index(),	10,	"Reverse, next index from start" );
ok( !$iter->at_start(),	"Reverse, not at start with next" );

$iter->forward(2); # now to 7

is( $iter->value(),	7,	"Reverse, forward in array" );
is( $iter->index(),	8,	"Reverse, forward in array" );

$iter->forward(20); # now way past end, back to end

is( $iter->value(),	undef,	"Reverse, forward past end" );
is( $iter->index(),	0,		"Reverse, forward past end" );
ok( $iter->at_end(),		"Reverse, at end with forward" );

$iter->next(); # again try to move past end

is( $iter->value(),	undef,	"Reverse, next past end" );
is( $iter->index(),	0,		"Reverse, next past end" );
ok( $iter->at_end(),		"Reverse, at end with next" );

$iter->prev(); # should be able to go back now

is( $iter->value(),	0,	"Reverse, prev from end" );
is( $iter->index(),	1,	"Reverse, prev from end" );
ok( !$iter->at_end(),	"Reverse, not at end with prev" );

$iter->backward(3); #back to 3

is( $iter->value(),	3,	"Reverse, backward from end" );
is( $iter->index(),	4,	"Reverse, backward from end" );

$iter->backward(20); #overshoot

is( $iter->value(),	10,	"Reverse, backward past start" );
is( $iter->index(),	11,	"Reverse, backward past start" );

$iter->to_end();

is( $iter->value(),	undef,	"Reverse, next past end" );
is( $iter->index(),	0,		"Reverse, next past end" );
ok( $iter->at_end(),		"Reverse, at end with next" );

$iter->to_start();

is( $iter->value(),	10,	"Reverse, to_start" );
is( $iter->index(),	11,	"Reverse, to_start" );
ok( $iter->at_start(),	"Reverse, to_start" );

# Shift/unshift at end

$iter->to_end();
shift @$iterarray;
is( $iter->value(),	undef,	"Reverse, shift at end" );
is( $iter->index(),	0,		"Reverse, shift at end" );

unshift @$iterarray, 0;
is( $iter->value(),	undef,	"Reverse, unshift at end" );
is( $iter->index(),	0,		"Reverse, unshift at end" );

# Shift/unshift elsewhere besides start

$iter->backward(4);
shift @$iterarray;
is( $iter->value(),	3,	"Reverse, shift in middle" );
is( $iter->index(),	3,	"Reverse, shift in middle" );

unshift @$iterarray, 0;
is( $iter->value(),	3,	"Reverse, unshift in middle" );
is( $iter->index(),	4,	"Reverse, unshift in middle" );

# Push/pop elsewhere besides end

pop @$iterarray;
is( $iter->value(),	3,	"Reverse, pop in middle" );
is( $iter->index(), 4,	"Reverse, pop in middle" );

push @$iterarray, 10;
is( $iter->value(),	3,	"Reverse, push in middle" );
is( $iter->index(), 4,	"Reverse, push in middle" );


# Push/pop at start

$iter->to_start();
pop @$iterarray;
is( $iter->value(),	9,		"Reverse, pop at start" );
is( $iter->index(), 10,		"Reverse, pop at start" );

push @$iterarray, 10;
is( $iter->value(),	10,		"Reverse, push at start" );
is( $iter->index(), 11,		"Reverse, push at start" );


# Splice before iterator (but not including it)
my @elems;

$iter->forward( 5 );  # Pointing to 5
@elems = splice @$iterarray, 0, 3;
is( $iter->value(), 5,		"Reverse, splice before" );
is( $iter->index(), 3,      "Reverse, splice before" );

splice @$iterarray, 0, 0, @elems;
is( $iter->value(), 5,		"Reverse, splice before" );
is( $iter->index(), 6,      "Reverse, splice before" );

# Splice including iterator

@elems = splice @$iterarray, 4, 3;
is( $iter->value(), 7,		"Reverse, splice including" );
is( $iter->index(), 5,      "Reverse, splice including" );

splice @$iterarray, 4, 0, @elems;
is( $iter->value(), 7,		"Reverse, splice including" );
is( $iter->index(), 8,      "Reverse, splice including" );

# Splice at iterator

$iter->forward( 2 );
@elems = splice @$iterarray, 5, 3;
is( $iter->value(), 8,		"Reverse, splice at" );
is( $iter->index(), 6,      "Reverse, splice at" );

splice @$iterarray, 5, 0, @elems;
is( $iter->value(), 8,		"Reverse, splice at" );
is( $iter->index(), 9,      "Reverse, splice at" );

# Splice after iterator

$iter->forward( 3 );
@elems = splice @$iterarray, 7, 3;
is( $iter->value(), 5,		"Reverse, splice after" );
is( $iter->index(), 6,		"Reverse, splice after" );

splice @$iterarray, 7, 0, @elems;
is( $iter->value(), 5,		"Reverse, splice after" );
is( $iter->index(), 6,		"Reverse, splice after" );

1;