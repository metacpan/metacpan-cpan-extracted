# $Id: PSU.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::PSU;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::PSU;

use Carp;
use strict;

sub selected                    { shift->{selected}                     }
sub chunk_cnt                   { shift->{chunk_cnt}                    }
sub state                       { shift->{state}                        }

sub set_selected                { shift->{selected}             = $_[1] }
sub set_chunk_cnt               { shift->{chunk_cnt}            = $_[1] }
sub set_state                   { shift->{state}                = $_[1] }

1;
