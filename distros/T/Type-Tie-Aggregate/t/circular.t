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
use Types::Standard qw(Int HashRef);
use Type::Tie::Aggregate;
use Test::More tests => 7;
use Test::Exception;

# Circular references can cause infinite recursion if not handled
# correctly, so make deep recursion an error. We can't use
# "no warnings FATAL => 'recursion'", because that only affects
# this scope, not the scope where the subroutines were defined.
local $SIG{__WARN__} = sub {
    die @_ if $_[0] =~ /^Deep recursion/;
};

# Circular references
# ===================

TODO: {
    local $TODO = 'Circular references not handled correctly yet';

    {
	my %hash;

	lives_ok {
	    ttie %hash, HashRef[HashRef|Int], (self => \%hash);
	} 'circular hash initialization';

	lives_and {
	    $hash{foo} = 1;
	    is $hash{foo}, 1;
	    $hash{self}{self}{foo}++;
	    is $hash{foo}, 2;
	} 'circular hash assignment';

	throws_ok { $hash{self}{self}{self}{foo} += 3.14 }
	    qr/did not pass type constraint/,
	    'invalid circular hash assignment';
    }

    {
	my $hashref;

	lives_ok {
	    my %init;
	    $init{self} = \%init;
	    ttie $hashref, HashRef[HashRef|Int], \%init;
	} 'circular hashref initialization';

	lives_and {
	    $hashref->{foo} = 1;
	    is $hashref->{foo}, 1;
	    $hashref->{self}{self}{foo}++;
	    is $hashref->{foo}, 2;
	} 'circular hashref assignment';

	throws_ok { $hashref->{self}{self}{self}{foo} += 3.14 }
	    qr/did not pass type constraint/,
	    'invalid circular hashref assignment';
    }
}
