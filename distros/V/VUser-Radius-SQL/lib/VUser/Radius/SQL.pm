package VUser::Radius::SQL;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: SQL.pm,v 1.9 2007/09/21 14:36:53 perlstalker Exp $

use VUser::ExtLib qw(:config);
use VUser::Log qw(:levels);
use VUser::ResultSet;
# Should be use()d by vuser when extensions are loaded.
# Explicitly include here to be sure
use VUser::Radius;
use VUser::ExtLib::SQL;

my $log;
my %meta;

our $VERSION = '0.1.1';
our $c_sec = 'Extension Radius::SQL';

my $extlib;
my $dsn;
my $username;
my $password;

sub c_sec { return $c_sec; }

sub depends { return qw(Radius); }

sub init {
    my $eh  = shift;
    my %cfg = @_;

    if ( defined $main::log ) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new( \%cfg, 'vuser' );
    }

    $dsn      = strip_ws( $cfg{$c_sec}{'dsn'} );
    $username = strip_ws( $cfg{$c_sec}{'username'} );
    $password = strip_ws( $cfg{$c_sec}{'password'} );

    $extlib = VUser::ExtLib::SQL->new(\%cfg,
				      {'dsn' => $dsn,
				       'user' => $username,
				       'password' => $password,
				       'macros' => { 'u' => 'username',
						     'p' => 'password',
						     'r' => 'realm',
						     'a' => 'attribute',
						     't' => 'type',
						     'v' => 'value'
						     }
				   });

    $eh->register_task( 'radius', 'adduser',   \&do_sql );
    $eh->register_task( 'radius', 'rmuser',    \&do_sql );
    $eh->register_task( 'radius', 'moduser',   \&radius_moduser );
    $eh->register_task( 'radius', 'listusers', \&radius_listusers );
    $eh->register_task( 'radius', 'userinfo',  \&radius_userinfo );

    $eh->register_task( 'radius', 'addattrib',  \&do_sql );
    $eh->register_task( 'radius', 'modattrib',  \&do_sql );
    $eh->register_task( 'radius', 'rmattrib',   \&do_sql );
    $eh->register_task( 'radius', 'listattrib', \&radius_listattrib );
}

sub unload { }

sub user_exists {
    my ($cfg, $opts) = @_;

    my $sql = strip_ws($cfg->{$c_sec}{'userinfo_query'});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql); };
    if ($@) {
        $log->log(LOG_ERROR, "Unable to get user info: $@");
        die "Unable to get user info: $@";
    }

    my $found;
    my @results;
    if (@results = $sth->fetchrow_array()) {
	$found = 1;
	$log->log(LOG_DEBUG, "User exists");
    } else {
	$found = 0;
	$log->log(LOG_DEBUG, "User does not exist");
    }

    $sth->finish;
    return $found;
}

sub do_sql {
    my ( $cfg, $opts, $action, $eh ) = @_;

    my $query;

    if ( $action eq 'adduser' ) {
	die "User ".$opts->{username}." exists\n" if user_exists($cfg, $opts);
        $query = 'adduser_query';
    } elsif ( $action eq 'rmuser' ) {
        $query = 'rmuser_query';
    } elsif ( $action eq 'addattrib' ) {
        if ( $opts->{'type'} == 'check' ) {
            $query = 'addattrib_check_query';
        } elsif ( $opts->{'type'} == 'reply' ) {
            $query = 'addattrib_reply_query';
        }
    } elsif ( $action eq 'rmattrib' ) {
        if ( $opts->{'type'} == 'check' ) {
            $query = 'rmattrib_check_query';
        } elsif ( $opts->{'type'} == 'reply' ) {
            $query = 'rmattrib_reply_query';
        }
    } elsif ( $action eq 'modattrib' ) {
        if ( $opts->{'type'} == 'check' ) {
            $query = 'modattrib_check_query';
        } elsif ( $opts->{'type'} == 'reply' ) {
            $query = 'modattrib_reply_query';
        }
    }

    my $sql = strip_ws( $cfg->{$c_sec}{$query} );

    if (not $sql) {
        $log->log(LOG_WARN, "No query specified for $query. Skipping.");
        return;
    }

    my $sth = $extlib->execute( $opts, $sql );
    $sth->finish;
}

sub radius_moduser {
    my ( $cfg, $opts, $action, $eh ) = @_;

    ## change password
    if ( $opts->{password} ) {
        $extlib->execute($opts,
			 strip_ws( $cfg->{$c_sec}{'moduser_password_query'} ));
    }
    ## change realm only
    if ( $opts->{newrealm} and not $opts->{newusername} ) {
        $extlib->execute($opts,
			 strip_ws( $cfg->{$c_sec}{'moduser_realm_query'} ) );
    }
    ## change username only
    if ( $opts->{newusername} and not $opts->{newrealm} ) {
        $extlib->execute($opts,
			 strip_ws( $cfg->{$c_sec}{'moduser_username_query'} ));
    }
    ## change username and realm
    if ( $opts->{newusername} and $opts->{newrealm} ) {
        $extlib->execute($opts,
			 strip_ws( $cfg->{$c_sec}{'moduser_userrealm_query'} ));
    }
}

sub radius_listusers {
    my ( $cfg, $opts, $action, $eh ) = @_;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta( $VUser::Radius::meta{'username'} );
    $rs->add_meta( $VUser::Radius::meta{'realm'} );

    my $sth =
      $extlib->execute( $opts, strip_ws( $cfg->{$c_sec}{'listusers_query'} ) );
    my @results;
    while ( @results = $sth->fetchrow_array ) {
        $rs->add_data( [ @results[ 0 .. 1 ] ] );
    }

    $sth->finish;
    return $rs;
}

sub radius_userinfo {
    my ( $cfg, $opts, $action, $eh ) = @_;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta( $VUser::Radius::meta{'username'} );
    $rs->add_meta( $VUser::Radius::meta{'realm'} );
    $rs->add_meta( $VUser::Radius::meta{'password'} );

    my $sth =
      $extlib->execute( $opts, strip_ws( $cfg->{$c_sec}{'userinfo_query'} ) );
    my @results;
    while ( @results = $sth->fetchrow_array ) {
        $rs->add_data( [ @results[ 0 .. 2 ] ] );
    }

    $sth->finish;
    return $rs;
}

sub radius_listattrib {
    my ( $cfg, $opts, $action, $eh ) = @_;

    my $sql;
    if ( $opts->{'type'} eq 'check' ) {
        $sql = strip_ws( $cfg->{$c_sec}{'listattrib_check_query'} );
    } elsif ( $opts->{'type'} eq 'reply' ) {
        $sql = strip_ws( $cfg->{$c_sec}{'listattrib_reply_query'} );
    }

    return unless $sql;

    ## Build resultset
    my $rs = VUser::ResultSet->new();
    $rs->add_meta( $VUser::Radius::meta{'username'} );
    $rs->add_meta( $VUser::Radius::meta{'realm'} );
    $rs->add_meta( $VUser::Radius::meta{'attribute'} );
    $rs->add_meta( $VUser::Radius::meta{'type'} );
    $rs->add_meta( $VUser::Radius::meta{'value'} );

    my $sth = $extlib->execute( $opts, $sql );

    my @results;
    while ( @results = $sth->fetchrow_array ) {
        $rs->add_data( [ @results[ 0 .. 2 ], $opts->{'type'}, $results[3] ] );
    }

    $sth->finish;
    return $rs;
}

1;

__END__

=head1 NAME

VUser::Radius::SQL - SQL support for the VUser::Radius vuser extension

=head1 DESCRIPTION

Adds support for storing RADIUS user information in a SQL database.

=head1 CONFIGURATION

 [vuser]
 extensions = Radius::SQL
 
 [Extension Radius::SQL]
 # Database driver to use.
 # The DBD::<driver> must exist or vuser will not be able to connect
 # to your database.
 # See perldoc DBD::<driver> for the format of this string for your database.
 dsn = DBI:mysql:database=database_name;host=localhost;post=3306

 # Database user name
 username = user
 
 # Database password
 # The password may not end with whitespace.
 password = secret
 
 ## SQL Queries
 # Here you define the queries used to add, modify and delete users and
 # attributes. There are a few predefined macros that you can use in your
 # SQL. The values will be quoted and escaped before being inserted into
 # the SQL.
 #  %u => username
 #  %p => password
 #  %r => realm
 #  %a => attribute name
 #  %v => attribute value
 #  %-option => This will be replaced by the value of --option passed in
 #              when vuser is run.
 
 # Add a RADIUS account
 adduser_query = INSERT into user set user = %u, password = %p, realm = %r
 
 # Delete a RADIUS account
 rmuser_query = DELETE from user where user = %s and realm = %r
 
 # Change a user's password
 moduser_password_query = UPDATE user set ...
 
 # Change an account's realm only
 moduser_realm_query = UPDATE user set ...
 
 # Change an account's username only
 moduser_username_query = UPDATE user set ...
 
 # Change both the username and the realm
 moduser_userrealm_query = UPDATE user set ...
 
 # Here, we need a way to map columns to values
 # Fixed columns:
 #   1 username
 #   2 realm
 listusers_query = SELECT username, realm from user
 
 # Here, we need a way to map columns to values
 # Fixed columns:
 #   1 username
 #   2 realm
 #   3 password
 userinfo_query = SELECT * from user where user = %s and realm = %r
 
 addattrib_check_query = INSERT into ...
 rmattrib_check_query  = DELETE from ...
 modattrib_check_query = UPDATE ...
 listattrib_check_query = SELECT ...
 
 addattrib_reply_query = INSERT into ...
 rmattrib_reply_query  = DELETE from ...
 modattrib_reply_query = UPDATE ...
 listattrib_reply_query = SELECT ...

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

