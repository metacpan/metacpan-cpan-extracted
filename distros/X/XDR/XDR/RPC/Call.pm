# Call.pm - SunRPC call packets
# Copyright (C) 2000  Mountain View Data, Inc.
# Written by Gordon Matzigkeit <gord@fig.org>, 2000-12-18
#
# This file is part of Perl XDR.
#
# Perl XDR is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Perl XDR is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# USA

package XDR::RPC::Call;
# [guilt]
# [maint
#  File: Call.pm
#  Summary: SunRPC call packets
#  Package: Perl XDR
#  Owner: Mountain View Data, Inc.
#  Years: 2000
#  Author: Gordon Matzigkeit
#  Contact: <gord@fig.org>
#  Date: 2000-12-18
#  License: GPL]
# [clemency]

use strict;

use vars qw(@ISA);
@ISA = qw(XDR::RPC);

use XDR::Decode;
use XDR::RPC;


sub finish_decode
{
    my ($type, $dec, $xid) = @_;

    my ($rpcvers, $prog, $vers, $proc, $cred, $verf) =
	($dec->unsigned,
	 $dec->unsigned,
	 $dec->unsigned,
	 $dec->unsigned,
	 $dec->opaque_auth,
	 $dec->opaque_auth);

    my ($args) = $dec->buffer (1);
    return $type->new($xid, [$rpcvers, $prog, $vers, $proc], $args,
		      $cred, $verf);
}


sub rpcvers
{
    my ($self) = @_;
    return $self->private->[0];
}


sub prog
{
    my ($self) = @_;
    return $self->private->[1];
}


sub vers
{
    my ($self) = @_;
    return $self->private->[2];
}


sub proc
{
    my ($self) = @_;
    return $self->private->[3];
}


# Simple support for replying to an RPC.
use XDR::Encode qw(reply_packet);
use XDR qw(MSG_ACCEPTED SUCCESS);
sub reply
{
    my ($self, $result) = @_;
    return reply_packet ($self->xid, MSG_ACCEPTED, SUCCESS, $result);
}


1;
