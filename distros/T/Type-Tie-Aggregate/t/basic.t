#!/usr/bin/env perl

######################################################################
# Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>                #
#                                                                    #
# This program is free software: you can redistribute it and/or      #
# modify it under the terms of the GNU General Public License as     #
# published by the Free Software Foundation, either version 3 of     #
# the License, or (at your option) any later version.                #
#                                                                    #
# This program is distributed in the hope that it will be useful,    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of     #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU   #
# General Public License for more details.                           #
#                                                                    #
# You should have received a copy of the GNU General Public License  #
# along with this program. If not, see                               #
# <http://www.gnu.org/licenses/>.                                    #
######################################################################

use v5.6.0;
use strict;
use warnings;
use Types::Standard qw(Num Int ArrayRef HashRef);
use Type::Tie::Aggregate;
use Test::More tests => 16;
use Test::Exception;

# An integer type that coerces from numbers.
my $NumToInt = Int->plus_coercions(Num, 'int');

# Scalars
# =======

{
    my $scalar;

    lives_and { ttie $scalar, $NumToInt, 5.6; is $scalar, 5 }
	'scalar initialization and coercion';

    throws_ok { ttie my $scalar, Num, 'foo' }
	qr/did not pass type constraint/,
	'invalid scalar initialization';

    lives_and { (tied $scalar)->initialize(6); is $scalar, 6 }
	'scalar re-initialization';

    lives_and { $scalar = 3.14; is $scalar, 3 }
	'scalar assignment and coercion';

    throws_ok { $scalar = 'foo' } qr/did not pass type constraint/,
	'invalid scalar assignment';
}

# Arrays
# ======

{
    my @array;

    lives_and {
	ttie @array, ArrayRef[$NumToInt], (1, 2, 3.14);
	is_deeply \@array, [1, 2, 3];
    } 'array initialization and coercion';

    throws_ok { ttie my @array, ArrayRef[Num], qw(one two three) }
	qr/did not pass type constraint/,
	'invalid array initialization';

    lives_and {
	(tied @array)->initialize(9, 10);
	is_deeply \@array, [9, 10];
    } 'array re-initialization';

    lives_and { push @array, 5.678; is_deeply \@array, [9, 10, 5] }
	'array assignment and coercion';

    throws_ok { push @array, 'foo' } qr/did not pass type constraint/,
	'invalid array assigment';
}

# Invalid coerced value detection
# ===============================

throws_ok {
    ttie my @array, HashRef->plus_coercions(ArrayRef, '+{ @$_ }'), (
	foo	=> 1,
	bar	=> 2,
    );
} qr/^Coerced to invalid value/, 'invalid coerced value detection';

# Hashes
# ======

{
    my %hash;

    lives_and {
	ttie %hash, HashRef[$NumToInt], (foo => 1, bar => 2.5);
	is_deeply \%hash, { foo => 1, bar => 2 };
    } 'hash initialization and coercion';

    throws_ok { ttie my %hash, HashRef[Num], (foo => 'bar') }
	qr/did not pass type constraint/,
	'invalid hash initialization';

    lives_and {
	(tied %hash)->initialize(foo => 5);
	is_deeply \%hash, { foo => 5 };
    } 'hash re-initialization';

    lives_and {
	$hash{bar} = 3.14;
	is_deeply \%hash, { foo => 5, bar => 3 };
    } 'hash assignment and coercion';

    throws_ok { $hash{baz} = 'forty-two' }
	qr/did not pass type constraint/, 'invalid hash assignment';
}
