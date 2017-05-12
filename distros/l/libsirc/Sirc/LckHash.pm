# $Id: LckHash.pm,v 1.3 2000-06-02 12:53:37-04 roderick Exp $
#
# Copyright (c) 1997-2000 Roderick Schertler.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;

package Sirc::LckHash;

# Lck == lower case key.  Hashes tied to this package will always use
# lower case keys.

use vars qw(@ISA);

require Tie::Hash;

@ISA = qw(Tie::StdHash);

sub STORE	{ $_[0]->{lc $_[1]} = $_[2] }
sub FETCH	{ $_[0]->{lc $_[1]} }
sub EXISTS	{ exists $_[0]->{lc $_[1]} }
sub DELETE	{ delete $_[0]->{lc $_[1]} }

1;
