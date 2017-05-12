#!/usr/bin/perl -w

#=============================================================================
#
# $Id: forward.t,v 0.03 2001/11/16 02:31:30 mneylon Exp $
# $Revision: 0.03 $
# $Author: mneylon $
# $Date: 2001/11/16 02:31:30 $
# $Log: forward.t,v $
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

# Forward iterator testing

use strict;
use Tie::Array::Iterable;

use Test::More tests => 62;

my @array = ( 0 .. 10 );

my $iterarray = new Tie::Array::Iterable( @array );

my $iter = $iterarray->from_start();

is( $iter->value(),	0,	"Forward, value from start" );
is( $iter->index(),	0,	"Forward, index from start" );
ok( $iter->at_start(),	"Forward, at start" );

$iter->prev();  # Should go nowhere

is( $iter->value(),	0,	"Forward, prev value from start" );
is( $iter->index(),	0,	"Forward, prev index from start" );
ok( $iter->at_start(),	"Forward, at start with prev" );

$iter->next();  # now go to 1

is( $iter->value(),	1,	"Forward, next value from start" );
is( $iter->index(),	1,	"Forward, next index from start" );
ok( !$iter->at_start(),	"Forward, not at start with next" );

$iter->forward(2); # now to 3

is( $iter->value(),	3,	"Forward, forward in array" );
is( $iter->index(),	3,	"Forward, forward in array" );

$iter->forward(20); # now way past end, back to end

is( $iter->value(),	undef,	"Forward, forward past end" );
is( $iter->index(),	11,		"Forward, forward past end" );
ok( $iter->at_end(),		"Forward, at end with forward" );

$iter->next(); # again try to move past end

is( $iter->value(),	undef,	"Forward, next past end" );
is( $iter->index(),	11,		"Forward, next past end" );
ok( $iter->at_end(),		"Forward, at end with next" );

$iter->prev(); # should be able to go back now

is( $iter->value(),	10,	"Forward, prev from end" );
is( $iter->index(),	10,	"Forward, prev from end" );
ok( !$iter->at_end(),	"Forward, not at end with prev" );

$iter->backward(3); #back to 7

is( $iter->value(),	7,	"Forward, backward from end" );
is( $iter->index(),	7,	"Forward, backward from end" );

$iter->backward(20); #overshoot

is( $iter->value(),	0,	"Forward, backward past start" );
is( $iter->index(),	0,	"Forward, backward past start" );

$iter->to_end();

is( $iter->value(),	undef,	"Forward, next past end" );
is( $iter->index(),	11,		"Forward, next past end" );
ok( $iter->at_end(),		"Forward, at end with next" );

$iter->to_start();

is( $iter->value(),	0,	"Forward, to_start" );
is( $iter->index(),	0,	"Forward, to_start" );
ok( $iter->at_start(),	"Forward, to_start" );

# Shift/unshift at start

shift @$iterarray;
is( $iter->value(),	1,	"Forward, shift at start" );
is( $iter->index(),	0,	"Forward, shift at start" );

unshift @$iterarray, 0;
is( $iter->value(),	0,	"Forward, unshift at start" );
is( $iter->index(),	0,	"Forward, unshift at start" );

# Shift/unshift elsewhere besides start

$iter->forward(4);
shift @$iterarray;
is( $iter->value(),	4,	"Forward, shift in middle" );
is( $iter->index(),	3,	"Forward, shift in middle" );

unshift @$iterarray, 0;
is( $iter->value(),	4,	"Forward, unshift in middle" );
is( $iter->index(),	4,	"Forward, unshift in middle" );

# Push/pop elsewhere besides end

pop @$iterarray;
is( $iter->value(),	4,	"Forward, pop in middle" );
is( $iter->index(), 4,	"Forward, pop in middle" );

push @$iterarray, 10;
is( $iter->value(),	4,	"Forward, push in middle" );
is( $iter->index(), 4,	"Forward, push in middle" );


# Push/pop at end

$iter->to_end();
pop @$iterarray;
is( $iter->value(),	undef,	"Forward, pop at end" );
is( $iter->index(), 10,		"Forward, pop at end" );

push @$iterarray, 10;
is( $iter->value(),	undef,	"Forward, push at end" );
is( $iter->index(), 11,		"Forward, push at end" );


# Splice before iterator (but not including it)
my @elems;

$iter->backward( 6 );  # Pointing to 5
@elems = splice @$iterarray, 0, 3;
is( $iter->value(), 5,		"Forward, splice before" );
is( $iter->index(), 2,      "Forward, splice before" );

splice @$iterarray, 0, 0, @elems;
is( $iter->value(), 5,		"Forward, splice before" );
is( $iter->index(), 5,      "Forward, splice before" );

# Splice including iterator

@elems = splice @$iterarray, 4, 3;
is( $iter->value(), 7,		"Forward, splice including" );
is( $iter->index(), 4,      "Forward, splice including" );

splice @$iterarray, 4, 0, @elems;
is( $iter->value(), 4,		"Forward, splice including" );
is( $iter->index(), 4,      "Forward, splice including" );

# Splice at iterator

$iter->forward( 1 );
@elems = splice @$iterarray, 5, 3;
is( $iter->value(), 8,		"Forward, splice at" );
is( $iter->index(), 5,      "Forward, splice at" );

splice @$iterarray, 5, 0, @elems;
is( $iter->value(), 5,		"Forward, splice at" );
is( $iter->index(), 5,      "Forward, splice at" );

# Splice after iterator

@elems = splice @$iterarray, 7, 3;
is( $iter->value(), 5,		"Forward, splice after" );
is( $iter->index(), 5,      "Forward, splice after" );

splice @$iterarray, 7, 0, @elems;
is( $iter->value(), 5,		"Forward, splice after" );
is( $iter->index(), 5,      "Forward, splice after" );

1;