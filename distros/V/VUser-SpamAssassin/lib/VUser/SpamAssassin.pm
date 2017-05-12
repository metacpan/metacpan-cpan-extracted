package VUser::SpamAssassin;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: SpamAssassin.pm,v 1.6 2007/04/12 17:23:30 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.6 $'))[1];
our $VERSION = "0.3.0";

use VUser::Meta;
use VUser::ResultSet;
use VUser::Extension;
push @ISA, 'VUser::Extension';

my %dbs = ('scores' => undef,
	   'awl' => undef,
	   'bayes' => undef);

my %meta = ('username' => VUser::Meta->new(name => 'username',
					   type => 'string',
					   description => 'User name'),
	    'option' => VUser::Meta->new (name => 'option',
					  type => 'string',
					  description => 'SA option'),
	    'value' => VUser::Meta->new (name => 'value',
					 type => 'string',
					 description => 'Value for option')
	    );

my $c_sec = 'Extension SpamAssassin';

sub c_sec { return $c_sec; }
sub meta { return %meta; }

sub init
{
    my $eh = shift;
    my %cfg = @_;

    # SA
    $eh->register_keyword('sa', 'Manage SpamAssassin settings');
    
    # SA-delall: Delete all options for a user.
    $eh->register_action('sa', 'delall');
    $eh->register_option('sa', 'delall', $meta{'username'}, 1);

    # SA-add: add an option for a user.
    $eh->register_action('sa', 'add');
    $eh->register_option('sa', 'add', $meta{'username'}, 1);
    $eh->register_option('sa', 'add', $meta{'option'}, 1);
    $eh->register_option('sa', 'add', $meta{'value'}, 1);

    # SA-mod: modify a user's options
    $eh->register_action('sa', 'mod');
    $eh->register_option('sa', 'mod', $meta{'username'}, 1);
    $eh->register_option('sa', 'mod', $meta{'option'}, 1);
    $eh->register_option('sa', 'mod', $meta{'value'});
    $eh->register_option('sa', 'mod',
			 VUser::Meta->new(name => 'delete',
					  type => 'boolean',
					  description => 'Delete the option')
			 );

    # SA-mod: delete an option for a user.
    $eh->register_action('sa', 'del');
    $eh->register_option('sa', 'del', $meta{'username'}, 1);
    $eh->register_option('sa', 'del', $meta{'option'}, 1);

    # SA-show: Show user settings
    $eh->register_action('sa', 'show');
    $eh->register_option('sa', 'show', $meta{'username'});
    $eh->register_option('sa', 'show', $meta{'option'});

    # Email
    $eh->register_keyword('email');

    # Email-del: When an email is deleted, we need to remove all their
    # settings as well.
    $eh->register_action('email', 'del');
}

sub unload {};

1;

__END__

=head1 NAME

VUser::SpamAssassin - vuser SpamAssassin support extension

=head1 DESCRIPTION

VUser::SpamAssassin is a generic extension that provides the keywords and actions used by
other VUser::SpamAssassin::* extensions. It is not meant to be used by itself.

=head1 CONFIGURATION

VUser::SpamAssassin doesn't have any configuration options itself. Other VUser::SpamAssassin::*
extensions may provide additional configuration options.

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
