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
use Types::Standard qw(Str Int Tuple Dict Optional);
use Type::Tie::Aggregate;
use Test::More tests => 15;
use Test::Exception;

# Tuples
# ======

{
    my @tuple;

    lives_and {
	ttie @tuple, Tuple[Str, Optional[Int]], ('foo');
	is_deeply \@tuple, ['foo'];
    } 'tuple initialization';

    throws_ok {
	# Int is not Optional this time.
	ttie my @tuple, Tuple[Str, Int], ('foo');
    } qr/did not pass type constraint/,
	'invalid tuple initialization';

    lives_and {
	push @tuple, 42;
	is_deeply \@tuple, ['foo', 42];
    } 'tuple assignment';

    throws_ok { push @tuple, 10 } qr/did not pass type constraint/,
	'invalid tuple assignment: too many';

    lives_and {
	pop @tuple;
	is_deeply \@tuple, ['foo', 42];
    } 'reset after: invalid tuple assignment: too many';

    throws_ok { $tuple[1] = 'bar' } qr/did not pass type constraint/,
	'invalid tuple assignment: invalid element type';
}

# Dicts
# =====

{
    my %dict;

    lives_and {
	ttie %dict, Dict[string => Str, number => Optional[Int]],
	    (string => 'foo');
	is_deeply \%dict, { string => 'foo' };
    } 'dict initialization';

    throws_ok {
	# Int is not Optional this time.
	ttie my %dict, Dict[string => Str, number => Int],
	    (string => 'foo');
    } qr/did not pass type constraint/, 'invalid dict initialization';

    lives_and {
	$dict{number} = 42;
	is_deeply \%dict, { string => 'foo', number => 42 };
    } 'dict assignment';

    throws_ok { $dict{invalid} = 3.14 }
	qr/did not pass type constraint/,
	'invalid dict assignment: invalid key';

    lives_and {
	delete $dict{invalid};
	is_deeply \%dict, { string => 'foo', number => 42 };
    } 'reset after: invalid dict assignment: invalid key';

    throws_ok { $dict{number} = 'two' }
	qr/did not pass type constraint/,
	'invalid dict assignment: invalid value type';

    lives_and {
	$dict{number} = 42;
	is_deeply \%dict, { string => 'foo', number => 42 };
    } 'reset after: invalid dict assignment: invalid value type';

    lives_and {
	delete $dict{number};
	is_deeply \%dict, { string => 'foo' };
    } 'dict deletion: optional key';

    throws_ok { delete $dict{string} }
	qr/did not pass type constraint/,
	'invalid dict deletion: required key';
}
