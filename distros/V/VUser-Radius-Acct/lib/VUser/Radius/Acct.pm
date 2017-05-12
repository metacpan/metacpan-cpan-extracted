package VUser::Radius::Acct;
use warnings;
use strict;

# Copyright 2007 Randy Smith <perlstalker@vuser.org>
# $Id: Acct.pm,v 1.2 2007/04/09 17:43:39 perlstalker Exp $

use VUser::Meta;
use VUser::Log;
use VUser::ResultSet;
use VUser::ExtLib qw(:config);

our $VERSION = '0.1.0';

our $c_sec = 'Extension Radius::Acct';
our %meta = ('username' => VUser::Meta->new('name' => 'username',
					    'type' => 'string',
					    'description' => 'User name'),
	     'password' => VUser::Meta->new('name' => 'password',
					    'type' => 'string',
					    'description' => 'User\'s password'),
	     'realm' => VUser::Meta->new('name' => 'realm',
					 'type' => 'string',
					 'description' => 'Realm for this user'),
	     'starttime' => VUser::Meta->new('name' => 'starttime',
					     'type' => 'string',
					     'description' => 'Start time. Format: "CCYY-MM-DD HH:mm:ss.h"'),
	     'endtime' => VUser::Meta->new('name' => 'endtime',
					   'type' => 'string',
					   'description' => 'End time. Format: "CCYY-MM-DD HH:mm:ss.h"'),
	     'phones' => VUser::Meta->new('name' => 'phones',
					  'type' => 'string',
					  'description' => 'Comma seperated list of called station IDs.'),
	     'report-type' => VUser::Meta->new('name' => 'report-type',
					       'type' => 'string',
					       'description' => 'Report type. "total" or "records" for total seconds and octets used or each connection record'),
	     # Common result set types
	     'session-id' => VUser::Meta->new('name' => 'session-id',
					      'type' => 'string',
					      'description' => 'Unique session ID'),
	     'timestamp' => VUser::Meta->new('name' => 'timestamp',
					     'type' => 'string',
					     'description' => 'Timestamp'),
	     'nas-ip-address' => VUser::Meta->new('name' => 'nas-ip-address',
						  'type' => 'string',
						  'description' => 'IP address of NAS'),
	     'session-time' => VUser::Meta->new('name' => 'session-time',
						'type' => 'int',
						'description' => 'Session time in seconds'),
	     'input-octets' => VUser::Meta->new('name' => 'input-octets',
						'type' => 'int',
						'description' => 'Number of input octets'),
	     'output-octets' => VUser::Meta->new('name' => 'output-octets',
						 'type' => 'int',
						 'description' => 'Number of output octets'),
	     'framed-ip-address' => VUser::Meta->new('name' => 'framed-ip-address',
						     'type' => 'string',
						     'description' => 'Framed IP address'),
	     'called-station-id' => VUser::Meta->new('name' => 'called-station-id',
						     'type' => 'string',
						     'description' => 'Called station ID'),
	     'calling-station-id' => VUser::Meta->new('name' => 'calling-station-id',
						      'type' => 'string',
						      'description' => 'Calling station id')
	     
	     );
my $log;

sub init {
    my $eh = shift;
    my %cfg = @_;

    if (defined $main::log) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new(\%cfg, 'vuser')
    }

    # Radius
    $eh->register_keyword ('radius', 'Manage RADIUS users');

    # radius-acct
    $eh->register_action ('radius', 'acct', 'View accouting data for a user');
    $eh->register_option ('radius', 'acct', $meta{'username'}, 'req');
    $eh->register_option ('radius', 'acct', $meta{'starttime'}, 'req');
    $eh->register_option ('radius', 'acct', $meta{'endtime'}, 'req');
    $eh->register_option ('radius', 'acct', $meta{'realm'});
    $eh->register_option ('radius', 'acct', $meta{'phones'});
    $eh->register_option ('radius', 'acct', $meta{'report-type'});

}

sub meta { return %meta; }
sub c_sec { return $c_sec; }

1;

=head1 NAME

VUser::Radius::Acct - vuser extension to view RADIUS accounting records

=head1 DESCRIPTION

VUser::Radius::Acct is an extension to vuser that allows one to view RADIUS
accounting data. VUser::Radius::Acct is not meant to be used by itself but,
instead, registers the basic keywords, actions and options that other
VUser::Radius::Acct::* extensions will use. Other options may be added by
RADIUS server specific extensions.

B<Note:> VUser::Radius::Acct does not need VUser::Radius to function.

=head1 CONFIGURATION

 [Extension Radius::Acct]

Any Radius::* extensions will automatically load I<Radius::Acct>. There is no
need to add I<Radius::Acct> to I<vuser|extensions>.
Other VUser::Radius::Acct::* extensions may have their own configuration.

=head1 META SHORTCUTS

VUser::Radius::Acct provides a few VUser::Meta objects that may be used by
other radius extensions. The safest way to access them is to call
VUser::Radius::Acct::meta() from within the extension's init() function.

Provided keys: username, password, realm, starttime, endtime, report-type

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of VUser-Radius-Acct.
 
 VUser-Radius-Acct is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-Radius is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with VUser-Radius-Acct; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
