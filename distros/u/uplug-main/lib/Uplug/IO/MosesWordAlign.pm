#-*-perl-*-
#####################################################################
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Uplug::IO::Tab - data records, row by row, 
#                separated by some delimiter symbol
#
#####################################################################
# $Author$
# $Id$

package Uplug::IO::MosesWordAlign;

use strict;
use vars qw(@ISA);
use Uplug::IO::Text;

@ISA = qw( Uplug::IO::Text );

#-------------------------------------------------------------------
#
# read is not implemented yet

sub read{
    my $self=shift;
    my ($data)=@_;
    die "read is not implemented for MosesWordAlign format ...";
}


# write is different from other streams: expects a array-ref with word-links (based on positions)

sub write{
    my $self  = shift;
    my $links = shift;

    die "no links found in Uplug::IO::MosesWordAlign::write!" 
	unless (ref($links) eq 'ARRAY');

    my $str = join(' ',sort { $a <=> $b } @{$links});

    my $fh=$self->{'FileHandle'};
    return $self->writeToHandle($fh,$str."\n");
}


# no header!

sub addheader{ }

1;

