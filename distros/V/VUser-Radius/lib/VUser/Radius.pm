package VUser::Radius;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: Radius.pm,v 1.11 2007/09/21 14:31:05 perlstalker Exp $

use VUser::Meta;
use VUser::Log;
use VUser::ResultSet;
use VUser::ExtLib qw(:config);

our $VERSION = '0.1.1';

our $c_sec = 'Extension Radius';
our %meta = ('username' => VUser::Meta->new('name' => 'username',
					    'type' => 'string',
					    'description' => 'User name'),
	     'password' => VUser::Meta->new('name' => 'password',
					    'type' => 'string',
					    'description' => 'User\'s password'),
	     'realm' => VUser::Meta->new('name' => 'realm',
					 'type' => 'string',
					 'description' => 'Realm for this user'),
	     'attribute' => VUser::Meta->new('name' => 'realm',
					     'type' => 'string',
					     'description' => 'Attribute to set for this user'),
	     'type' => VUser::Meta->new('name' => 'type',
					'type' => 'string',
					'description' => '\'check\' or \'reply\''),
	     'value' => VUser::Meta->new('name' => 'value',
					 'type' => 'string',
					 'description' => 'Value of passed attribute')
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

    # radius-adduser
    $eh->register_action ('radius', 'adduser', 'Add a user to RADIUS');
    $eh->register_option ('radius', 'adduser', $meta{'username'}, 'req');
    $eh->register_option ('radius', 'adduser', $meta{'password'}, 'req');
    $eh->register_option ('radius', 'adduser', $meta{'realm'});

    # radius-rmuser
    $eh->register_action ('radius', 'rmuser', 'Remove a user from RADIUS');
    $eh->register_option ('radius', 'rmuser', $meta{'username'}, 'req');
    $eh->register_option ('radius', 'rmuser', $meta{'realm'});

    # radius-moduser
    $eh->register_action ('radius', 'moduser', 'Modify a RADIUS user');
    $eh->register_option ('radius', 'moduser', $meta{'username'}, 'req');
    $eh->register_option ('radius', 'moduser', $meta{'realm'});
    $eh->register_option ('radius', 'moduser', $meta{'username'}->new('name' => 'newusername'));
    $eh->register_option ('radius', 'moduser', $meta{'password'});
    $eh->register_option ('radius', 'moduser', $meta{'realm'}->new('name' => 'newrealm'));

<<<<<<< Radius.pm
    # radius-listusers
    $eh->register_action ('radius', 'listusers', 'List RADIUS users');
    $eh->register_option ('radius', 'listusers', $meta{'username'});
    $eh->register_option ('radius', 'listusers', $meta{'realm'});

    # radius-userinfo
    $eh->register_action ('radius', 'userinfo', 'List RADIUS user details');
    $eh->register_option ('radius', 'userinfo', $meta{'username'}, 'req');
    $eh->register_option ('radius', 'userinfo', $meta{'realm'});

=======
	# radius-listusers
	$eh->register_action ('radius', 'listusers', 'List all user accounts');
	
	# radius-userinfo
	$eh->register_action ('radius', 'userinfo', 'Get details for a RADIUS user');
	$eh->register_option ('radius', 'userinfo', $meta{'username'}, 'req');
	$eh->register_option ('radius', 'userinfo', $meta{'realm'});
	
>>>>>>> 1.8
    # radius-addattrib
    $eh->register_action ('radius', 'addattrib', 'Add an attribute to a RADIUS user');
    $eh->register_option ('radius', 'addattrib', $meta{'username'}, 1);
    $eh->register_option ('radius', 'addattrib', $meta{'realm'});
    $eh->register_option ('radius', 'addattrib', $meta{'attribute'}, 1);
    $eh->register_option ('radius', 'addattrib', $meta{'value'}, 1);

    # radius-modattrib
    $eh->register_action ('radius', 'modattrib', 'Modify an attribute for a RADIUS user');
    $eh->register_option ('radius', 'modattrib', $meta{'username'}, 1);
    $eh->register_option ('radius', 'modattrib', $meta{'realm'});
    $eh->register_option ('radius', 'modattrib', $meta{'attribute'}, 1);
    $eh->register_option ('radius', 'modattrib', $meta{'value'});

    # radius-rmattrib
    $eh->register_action ('radius', 'rmattrib', 'Remove an attribute from a RADIUS user');
    $eh->register_option ('radius', 'rmattrib', $meta{'username'}, 1);
    $eh->register_option ('radius', 'rmattrib', $meta{'realm'});
    $eh->register_option ('radius', 'rmattrib', $meta{'attribute'}, 1);
<<<<<<< Radius.pm

    # radius-listattrib
    $eh->register_action ('radius', 'listattrib', 'List the attribute(s) for a RADIUS user');
    $eh->register_option ('radius', 'listattrib', $meta{'username'}, 1);
    $eh->register_option ('radius', 'listattrib', $meta{'realm'});
    $eh->register_option ('radius', 'listattrib', $meta{'attribute'});
=======
    
    # radius-listattrib
    $eh->register_action ('radius', 'listattrib', 'List attributes for a RADIUS user');
    $eh->register_option ('radius', 'listattrib', $meta{'username'}, 1);
    $eh->register_option ('radius', 'listattrib', $meta{'realm'});
    $eh->register_option ('radius', 'listattrib', $meta{'type'}, 1);
<<<<<<< Radius.pm
>>>>>>> 1.8
=======
    
    # radius-allowedattribs
    $eh->register_action ('radius', 'allowedattribs', 'List allowed attributes for RADIUS');
    $eh->register_task ('radius', 'allowedattribs', \&radius_allowedattribs);
>>>>>>> 1.10
}

sub meta { return %meta; }
sub c_sec { return $c_sec; }

sub radius_allowedattribs {
    my ($cfg, $opts, $action, $eh) = @_;
    
    my @attribs = ();

    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'attribute'});
    $rs->add_meta($meta{'type'});
    
    # Name[:check|reply] (defaults to 'reply')
    my $values = strip_ws($cfg->{c_sec()}{'allowed attributes'});
    
    if (defined $values) {
        my @attrib_pairs = split (/ /, $values);
        foreach my $attrib_pair (@attrib_pairs) {
            my ($attrib, $type) = split (':', $attrib_pair);
            if (not defined ($type)
                or ($type ne 'reply' and $type ne 'check')) {
                $type = 'reply';
            }
            $rs->add_data([$attrib, $type]); 
        }
    }
    return $rs;
}

1;

__END__

=head1 NAME

VUser::Radius - vuser extension to manage RADIUS users

=head1 DESCRIPTION

VUser::Radius is an extension to vuser that allows one to manage RADIUS
users. VUser::Radius is not meant to be used by itself but, instead,
registers the basic keywords, actions and options that other VUser::Radius::*
extensions will use. Other options may be added by RADIUS server specific
extensions.

=head1 CONFIGURATION

 [Extension Radius]
 # List of allowed RADIUS attributes. The attributes are seperated by whitespace.
 # Each attribute may, optionally, be follwed by a ':' and the words 'reply' or 'check'
 # to identify the attribute type. 'reply' is assumed if no type (or an unknown type)
 # is specified.
 #
 # Note: This is list is not currently used by radius|addattrib and friends to test
 # if the passed attribute is allowed. 
 allowed attributes = Framed-IP-Address Framed-Netmask Simultaneous-Use:check

Any Radius::* extensions will automatically load I<Radius>. There is no
need to add I<Radius> to I<vuser|extensions>.
Other VUser::Radius::* extensions may have their own configuration.

=head1 META SHORTCUTS

VUser::Radius provides a few VUser::Meta objects that may be used by
other radius extensions. The safest way to access them is to call
VUser::Radius::meta() from within the extension's init() function.

Provided keys: username, password, realm, attribute, type, value

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of VUser-Radius.
 
 VUser-Radius is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-Radius is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
