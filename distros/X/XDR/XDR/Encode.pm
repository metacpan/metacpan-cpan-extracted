# Encode.pm - build XDR strings from Perl objects
# Copyright (C) 2000  Mountain View Data, Inc.
# Written by Gordon Matzigkeit <gord@fig.org>, 2000-12-14
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

package XDR::Encode;
# [guilt]
# [maint
#  File: Encode.pm
#  Summary: build XDR strings from Perl objects
#  Package: Perl XDR
#  Owner: Mountain View Data, Inc.
#  Years: 2000
#  Author: Gordon Matzigkeit
#  Contact: <gord@fig.org>
#  Date: 2000-12-14
#  License: GPL]
# [clemency]


use strict;
use Carp;

BEGIN
{
    use Exporter ();
    use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);
    @ISA = qw(Exporter);
    $EXPORT_TAGS{packet} = [qw(&call_packet &reply_packet &packet)];
    $EXPORT_TAGS{simple} = [qw(&opaque &unsigned &void)];
    $EXPORT_TAGS{all} = [@{$EXPORT_TAGS{packet}}, @{$EXPORT_TAGS{simple}},
			 '&record', '&opaque_auth'];
    Exporter::export_ok_tags ('all');
}

use XDR qw(:msg_type :auth_flavor RPCVERS AUTH_NULL MSG_ACCEPTED);


# Encode a generic packet.
my $global_xid = 0;
sub packet
{
    my ($msg_type, $contents, $xid) = @_;
    $xid = $global_xid ++ if (! defined $xid);
    return unsigned ($xid) . unsigned ($msg_type) . $contents;
}


# Return an RPC record.
sub record
{
    my ($data) = @_;
    my ($len) = length ($data) | (1 << 31);
    return unsigned ($len) . $data;
}


# Encode an unsigned integer.
sub unsigned
{
    my ($data) = @_;
    confess "Non-numeric data for pack" if ($data !~ /^\d+$/);
    pack ('N', $data);
}


sub opaque_auth
{
    my ($flavor, $body) = @_;
    $body = '' if (! defined $body);
    unsigned ($flavor) . opaque ($body);
}


sub opaque
{
    my ($data) = @_;
    my ($len) = length ($data);

    # Align to int boundaries.
    my $dribble = $len & 3;
    if ($dribble)
    {
	$data .= "\0" x (4 - $dribble);
    }

    return unsigned ($len) . $data;
}


sub void
{
    # This isn't undef so we don't get warnings.
    return '';
}


# Construct a call packet.
sub call_packet
{
    my ($xid, $proc, $args, $vers, $prog, $rpcvers) = @_;

    $rpcvers = RPCVERS if (! defined $rpcvers);
    return packet (CALL,
		   unsigned ($rpcvers) . # rpcvers
		   unsigned ($prog) . # prog
		   unsigned ($vers) . # vers
		   unsigned ($proc) . # proc
		   opaque_auth (AUTH_NULL) . # cred
		   opaque_auth (AUTH_NULL) . # verf
		   $args,
		   $xid);
}


# Construct a reply packet.
sub reply_packet
{
    my ($xid, $status, $reason, $args) = @_;
    
    my ($verf);
    $args = '' if (! defined $args);
    $verf = opaque_auth (AUTH_NULL) if ($status == MSG_ACCEPTED);
    return packet (REPLY,
		   $verf .
		   unsigned ($status) .
		   unsigned ($reason) .
		   $args,
		   $xid);
}


1;
