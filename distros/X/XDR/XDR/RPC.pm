# RPC.pm - base class for SunRPC packets
# Copyright (C) 2000  Mountain View Data, Inc.
# Written by Gordon Matzigkeit <gord@fig.org>, 2000-12-16
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

package XDR::RPC;
# [guilt]
# [maint
#  File: RPC.pm
#  Summary: base class for SunRPC packets
#  Package: Perl XDR
#  Owner: Mountain View Data, Inc.
#  Years: 2000
#  Author: Gordon Matzigkeit
#  Contact: <gord@fig.org>
#  Date: 2000-12-16
#  License: GPL]
# [clemency]

use strict;
use Carp;

use XDR ':msg_type';
use XDR::Decode;

sub XID () {0}
sub PRIVATE () {1}
sub ARGS () {2}
sub CRED () {3}
sub VERF () {4}
sub COOKED_ARGS () {5}

sub new
{
    my ($type, $xid, $private, $args, $cred, $verf) = @_;
    return bless [$xid, $private, $args, $cred, $verf], $type;
}


sub xid
{
    my ($self) = @_;
    return $self->[XID];
}


sub private
{
    my ($self) = @_;
    return $self->[PRIVATE];
}


sub cred
{
    my ($self) = @_;
    return $self->[CRED];
}


sub verf
{
    my ($self) = @_;
    return $self->[VERF];
}


# Unpack the arguments to or result from an RPC.
sub args
{
    my ($self, $callrep, @proto) = @_;

    if ($#proto < 0)
    {
	# Return the raw arguments...
	return $self->[ARGS] if (! defined $callrep);

	# Or something from the last cooked ones.
	return $self->[COOKED_ARGS]->[$callrep];
    }
    my ($dec) = XDR::Decode->new ($self->[ARGS]);

    my (@args, $i);
    for ($i = 0; $i <= $#proto; $i ++)
    {
	my ($type, $name) = split (/ /, $proto[$i]);
	my $tname = $type;
	while (! ref $type && defined $callrep->{TYPES}->{$type})
	{
	    $tname = $type;
	    $type = $callrep->{TYPES}->{$type};
	}

	if (ref $type)
	{
	    # Decode an interface-defined structure.
	    push (@args, eval "\$callrep->struct ('$tname', \$dec)");
	}
	else
	{
	    # Decode a basic type.
	    push (@args, eval "\$dec->$type;");
	}
	croak $@ if $@;
    }

    my $leftlen = length ($dec->buffer (1));
    croak "$leftlen too many bytes in RPC arguments"
	if ($leftlen > 0);

    # Cache the decoded values.
    $self->[COOKED_ARGS] = \@args;
    return @args;
}


# Unpack the buffer as if it is an RPC.
sub decode
{
    my ($type, $dec) = @_;

    $dec = XDR::Decode->new ($dec)
	if (! UNIVERSAL::isa ($dec, 'XDR::Decode'));

    my ($xid) = $dec->unsigned;
    my ($msg_type) = $dec->unsigned;

    if ($msg_type == CALL)
    {
	require 'XDR/RPC/Call.pm';
	return XDR::RPC::Call->finish_decode ($dec, $xid);
    }
    elsif ($msg_type == REPLY)
    {
	require 'XDR/RPC/Reply.pm';
	return XDR::RPC::Reply->finish_decode ($dec, $xid);
    }
    else
    {
	croak "Unrecognized msg_type $msg_type";
    }
}


1;
