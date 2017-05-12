package VUser::SpamAssassin::SQL;
use warnings;
use strict;

# Copyright (c) 2007 Randy Smith <perlstalker@vuser.org>
# $Id: SQL.pm,v 1.1 2007/04/11 21:42:45 perlstalker Exp $

our $VERSION = '0.1.0';

use VUser::Log qw(:levels);
use VUser::ResultSet;
use VUser::SpamAssassin;
use VUser::Meta;
use VUser::ExtLib qw(:config);
use VUser::ExtLib::SQL;
use VUser::Extension;
use base qw(VUser::Extension);

our $log;
our $c_sec = 'Extension SpamAssassin::SQL';
our %meta;
our $db;
my $dsn;
my $username;
my $password;


sub meta { return %meta; }
sub c_sec { return $c_sec; }
sub db { return $db; }

sub depends { return qw(SpamAssassin); }

sub unload {};

sub init {
    my $eh = shift;
    my %cfg = @_;
    
    if ( defined $main::log ) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new( \%cfg, 'vuser' );
    }
    
    %meta = VUser::SpamAssassin::meta();
    
    $dsn      = strip_ws( $cfg{$c_sec}{'dsn'} );
    $username = strip_ws( $cfg{$c_sec}{'username'} );
    $password = strip_ws( $cfg{$c_sec}{'password'} );
    
    $db = VUser::ExtLib::SQL->new(\%cfg,
        		      {'dsn' => $dsn,
				       'user' => $username,
				       'password' => $password,
				       'macros' => { 'u' => 'username',
						     'o' => 'option',
						     'v' => 'value'
						     }
				   });
}

1;

__END__

=head1 NAME

VUser::SpamAssassin::SQL - vuser SpamAssassin SQL support extension

=head1 DESCRIPTION

VUser::SpamAssassin::SQL is a parent extension for other VUser::SpamAssassin::SQL::* modules.
It allows other SA::SQL extensions to use the same DB handle.

=head1 CONFIGURATION

 [Extension SpamAssassin::SQL]
 # User scores database username and password.
 # The DSN's here are in the same format as defined in the sql/README*
 # files in the SpamAssassin package.
 # This user needs select, insert and delete permissions.
 dsn = dbi:mysql:localhost
 username = sa
 password = a-password

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of VUser-SpamAssassin-SQL.
 
 VUser-SpamAssassin-SQL is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-SpamAssassin-SQL is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with VUser-SpamAssassin-SQL; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
