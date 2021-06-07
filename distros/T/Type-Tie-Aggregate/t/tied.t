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
use Types::Standard qw(Str Int ArrayRef HashRef);
use Tie::RefHash;
use Type::Tie::Aggregate;
use Test::More tests => 6;
use Test::Exception;

{
    ttie my @array, ArrayRef[HashRef[Int]];

    my $scalar_key = \'scalar';
    my $array_key = [1, 2, 3];
    tie my %refhash, 'Tie::RefHash', (
	$scalar_key	=> 1,
	$array_key	=> 2,
    );

    push @array, \%refhash;

    lives_ok { $array[0]{$scalar_key} = 42 }
	'tied hash assignment, ref key';

    lives_ok { $array[0]{"$scalar_key"} = 100 }
	'tied hash assignment, string key';

    # Convert this to an array so that is_deeply() handles the ref
    # keys properly.
    my @got = map [$_ => $array[0]{$_}], keys %{$array[0]};
    my @expected = (
	[$scalar_key	=> 42],
	["$scalar_key"	=> 100],
	[$array_key		=> 2],
    );
    @$_ = sort { $a->[1] <=> $b->[1] } @$_ foreach \@got, \@expected;

    is_deeply \@got, \@expected, 'tied hash value';

    throws_ok { $array[0]{$array_key} = 'foo' }
	qr/did not pass type constraint/,
	'invalid tied hash assignment, ref key';

    # Reset after above.
    $array[0]{$array_key} = 2;

    throws_ok { $array[0]{"$array_key"} = 'bar' }
	qr/did not pass type constraint/,
	'invalid tied hash assignment, string key';
}

# Check tying references already tied to a different variable tied to
# a type.

# FIXME: Does this follow the principle of least surprise?

{
    ttie my @int_array, ArrayRef[ArrayRef[Int]];
    ttie my @str_array, ArrayRef[ArrayRef[Str]];
    my $arrayref = [];

    push @int_array, $arrayref;
    throws_ok { push @str_array, $arrayref } qr/already tied to/,
	'disallowed retying to a different typed variable';
}
