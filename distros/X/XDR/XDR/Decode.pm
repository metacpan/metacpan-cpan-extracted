# Decode.pm - objects to deserialize XDR strings
# Copyright (C) 2000  Mountain View Data, Inc.
# Written by Gordon Matzigkeit <gord@fig.org>, 2000-12-15
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

package XDR::Decode;
# [guilt]
# [maint
#  File: Decode.pm
#  Summary: objects to deserialize XDR strings
#  Package: Perl XDR
#  Owner: Mountain View Data, Inc.
#  Years: 2000
#  Author: Gordon Matzigkeit
#  Contact: <gord@fig.org>
#  Date: 2000-12-15
#  License: GPL]
# [clemency]

use strict;
use Carp;


# Initialize a new decoding session.
sub new
{
    my ($type, $buf) = @_;
    bless { buffer => $buf, offset => 0 }, $type;
}


# Append bytes to the decoding buffer.
sub append
{
    my ($self, $data) = @_;
    $self->{buffer} .= $data;
}


# Return the unconsumed buffer.
sub buffer
{
    my ($self, $truncate) = @_;

    my $ret = substr ($self->{buffer}, $self->{offset});
    if ($truncate)
    {
	$self->{buffer} = '';
	$self->{offset} = 0;
    }
    return $ret;
}


# Add an RPC record fragment to the buffer.  Return the unused bytes,
# if any.
sub fragment
{
    my ($self, $rec) = @_;
    my $dec = XDR::Decode->new ($rec);
    my $len = $dec->unsigned;

    $self->append ($dec->inline ($len & ~(1 << 31)));
    my $left = $dec->buffer;
    my $leftlen = length $left;
    croak "$leftlen too many bytes in RPC record.\n"
	if ($len >> 31 && $leftlen > 0);

    return $leftlen && $left;
}


# Add a complete RPC record to the buffer.
sub record
{
    my ($self, $rec) = @_;
    my $remain;
    do
    {
	$remain = $self->fragment ($rec);
    } while ($remain);
}


# Fetch N bytes from the buffer.
sub inline
{
    my ($self, $n) = @_;
    my $left = length ($self->{buffer}) - $self->{offset};

    croak "Need $n bytes, but only have $left remaining in XDR buffer.\n"
	if ($n > $left);

    # Take the slice they asked for.
    my $ret = substr ($self->{buffer}, $self->{offset}, $n);

    # Advance the offset pointer.
    $self->{offset} += $n;
    if ($self->{offset} >= length $self->{buffer})
    {
	# Truncate the buffer to conserve memory.
	$self->{offset} = 0;
	$self->{buffer} = '';
    }

    return $ret;
}


# Decode nothing at all.
sub void
{
    return '';
}


# Decode an unsigned integer.
sub unsigned
{
    my $self = shift;
    return unpack ('N', $self->inline (4));
}


# Decode a variable-length opaque.
sub opaque
{
    # opaque -> ()
    # opaque[0] -> (0)
    # opaque[10] -> (10)
    # opaque<20> -> (0, 20)
    my ($self, $min, $max) = @_;

    $min = $self->unsigned () if (! defined $min);
    croak "Opaque length $min exceeds maximum $max."
	if (defined $max && $min > $max);
    my $ret = $self->inline ($min);
    
    # Strip the padded zeros.
    my $dribble = $min & 3;
    if ($dribble)
    {
	$self->inline (4 - $dribble);
    }

    return $ret;
}


sub opaque_auth
{
    my ($self) = @_;
    return [ $self->unsigned, $self->opaque ];
}


# Unpack an RPC buffer.
use XDR::RPC;
sub rpc
{
    my ($self) = @_;
    return XDR::RPC->decode ($self);
}


1;
