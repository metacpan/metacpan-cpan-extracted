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
use Test::More tests => 9;
use Test::Exception;

# An integer type that coerces from numbers.
my $NumToInt = Int->plus_coercions(Num, 'int');

# Scalars
# =======

{
    my $scalar;

    lives_and {
	ttie $scalar, ArrayRef[ArrayRef[ArrayRef[$NumToInt]]], [];
	is_deeply $scalar, [];
    } 'scalar deep tying';

    throws_ok { push @$scalar, [qw(foo bar baz)] }
	qr/did not pass type constraint/,
	'invalid scalar ref assignment';

    # Re-initialize after test above.
    (tied $scalar)->initialize([]);

    lives_and {
	push @$scalar, [];
	push @{$scalar->[0]}, [1, 2, 3.5];
	is_deeply $scalar, [[[1, 2, 3]]];
    } 'scalar ref assignment';

    lives_and {
	push @{$scalar->[0][0]}, 4;
	is_deeply $scalar, [[[1, 2, 3, 4]]];
    } 'scalar ref deep assignment';

    throws_ok { push @{$scalar->[0][0]}, 'foo' }
	qr/did not pass type constraint/,
	'invalid scalar ref deep assignment';
}

# Arrays
# ======

{
    my @array;

    lives_and {
	ttie @array, ArrayRef[ArrayRef[$NumToInt]], ([1, 2, 3]);
	is_deeply \@array, [[1, 2, 3]];
    } 'array deep tying';

    throws_ok { push @{$array[0]}, 'foo' }
	qr/did not pass type constraint/,
	'array ref invalid deep assignment';
}

# Hashes
# ======

{
    my %hash;

    lives_and {
	ttie %hash, HashRef[ArrayRef[$NumToInt]], (foo => [1, 2, 3]);
	is_deeply \%hash, { foo => [1, 2, 3] };
    } 'hash deep tying';

    throws_ok { push @{$hash{foo}}, 'foo' }
	qr/did not pass type constraint/,
	'array ref invalid deep assignment';
}
