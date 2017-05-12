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
#####################################################################
#
# XML
#
#####################################################################
# $Author$
# $Id$
#
# Note: XML without encoding-specification will be treated as latin1!
#       (look at readFromHandle)
#

package Uplug::IO::Storable;

use strict;
use vars qw(@ISA $STOREMAX);

use Storable;
# $Storable::drop_utf8=1;

use Uplug::Encoding;
use Uplug::IO;

@ISA = qw( Uplug::IO::Text );
$STOREMAX = 5000;


sub read{
    my $self=shift;
    my $data=shift;
    if (not ref($data)){return 0;}
#    $data->init;
    my $fh=$self->{'FileHandle'};
    binmode($fh);
    $data->{__STORED__}=Storable::fd_retrieve($fh);
    if (not ref($data->{__STORED__})){return 0;}
    foreach (keys %{$data->{__STORED__}}){
	$data->{$_}=$data->{__STORED__}->{$_};
    }
    return 1;
}


sub write{
    my $self=shift;
    my $data=shift;
    if (not ref($data)){return 0;}
    my $fh=$self->{'FileHandle'};
    binmode($fh);
    my $ref=Storable::store_fd($data,$fh);
}


