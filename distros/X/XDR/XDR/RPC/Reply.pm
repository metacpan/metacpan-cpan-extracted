# Reply.pm - SunRPC reply packets
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

package XDR::RPC::Reply;
# [guilt]
# [maint
#  File: Reply.pm
#  Summary: SunRPC reply packets
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
use XDR qw(:reply_stat :accept_stat :reject_stat);


sub finish_decode
{
    my ($type, $dec, $xid) = @_;

    my (@priv, $verf, $result, $reason);
    my ($status) = $dec->unsigned;
    if ($status == MSG_ACCEPTED)
    {
	$verf = $dec->opaque_auth;
	$reason = $dec->unsigned;
	if ($reason == SUCCESS)
	{
	    $result = $dec->buffer (1);
	}
	elsif ($reason == PROG_MISMATCH)
	{
	    # low, high
	    push @priv, ($dec->unsigned, $dec->unsigned);
	}
    }
    elsif ($status == MSG_DENIED)
    {
	$reason = $dec->unsigned;
	if ($reason == RPC_MISMATCH)
	{
	    # low, high
	    push @priv, ($dec->unsigned, $dec->unsigned);
	}
	elsif ($reason == AUTH_ERROR)
	{
	    # auth_stat
	    push @priv, $dec->unsigned;
	}
    }

    return $type->new($xid, [$status, $reason, @priv], $result,
		      undef, $verf);
}


sub status
{
    my ($self) = @_;
    return $self->private->[0];
}


sub reason
{
    my ($self) = @_;
    return $self->private->[1];
}


sub result
{
    my ($self) = @_;
    return $self->args ();
}


1;
