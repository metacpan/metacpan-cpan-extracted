# XDR.pm - XDR constants
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

package XDR;
# [guilt]
# [maint
#  File: XDR.pm
#  Summary: XDR constants
#  Package: Perl XDR
#  Owner: Mountain View Data, Inc.
#  Years: 2000
#  Author: Gordon Matzigkeit
#  Contact: <gord@fig.org>
#  Date: 2000-12-14
#  License: GPL]
# [clemency]

use strict;

use vars qw(@ISA);

BEGIN
{
    use Exporter ();
    use vars qw(@EXPORT_OK %EXPORT_TAGS @ISA $VERSION);
    $VERSION = '0.03';
    @ISA = qw(Exporter);
    $EXPORT_TAGS{vers} = [qw(&RPCVERS)];
    $EXPORT_TAGS{auth_flavor} = [qw(&AUTH_NULL &AUTH_UNIX &AUTH_SHORT
				    &AUTH_DES)];
    $EXPORT_TAGS{msg_type} = [qw(&CALL &REPLY)];
    $EXPORT_TAGS{reply_stat} = [qw(&MSG_ACCEPTED &MSG_DENIED)];
    $EXPORT_TAGS{accept_stat} = [qw(&SUCCESS &PROG_UNAVAIL
				    &PROG_MISMATCH &PROC_UNAVAIL
				    &GARBAGE_ARGS &SYSTEM_ERR)];
    $EXPORT_TAGS{reject_stat} = [qw(&RPC_MISMATCH &AUTH_ERROR)];
    $EXPORT_TAGS{auth_stat} = [qw(&AUTH_BADCRED &AUTH_REJECTEDCRED
				  &AUTH_BADVERF &AUTH_REJECTEDVERF
				  &AUTH_TOOWEAK)];
    $EXPORT_TAGS{all} =
	[@{$EXPORT_TAGS{vers}}, @{$EXPORT_TAGS{auth_flavor}},
	 @{$EXPORT_TAGS{msg_type}},
	 @{$EXPORT_TAGS{reply_stat}}, @{$EXPORT_TAGS{accept_stat}},
	 @{$EXPORT_TAGS{reject_stat}}, @{$EXPORT_TAGS{auth_stat}}];
    Exporter::export_ok_tags ('all');
}


# vers
sub RPCVERS () {2}

# auth_flavor
sub AUTH_NULL () {0}
sub AUTH_UNIX () {1}
sub AUTH_SHORT () {2}
sub AUTH_DES () {3}

# auth_stat
sub AUTH_BADCRED () {1}
sub AUTH_REJECTEDCRED () {2}
sub AUTH_BADVERF () {3}
sub AUTH_REJECTEDVERF () {4}
sub AUTH_TOOWEAK () {5}

# msg_type
sub CALL () {0}
sub REPLY () {1}

# reply_stat
sub MSG_ACCEPTED () {0}
sub MSG_DENIED () {1}

# accept_stat
sub SUCCESS () {0}
sub PROG_UNAVAIL () {1}
sub PROG_MISMATCH () {2}
sub PROC_UNAVAIL () {3}
sub GARBAGE_ARGS () {4}
sub SYSTEM_ERR () {5}

# reject_stat
sub RPC_MISMATCH () {0}
sub AUTH_ERROR () {1}

1;
