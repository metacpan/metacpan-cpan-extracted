package VUser::SpamAssassin::SQL::Userprefs;
use warnings;
use strict;

# Copyright (c) 2007 Randy Smith <perlstalker@vuser.org>
# $Id: Userprefs.pm,v 1.2 2007/04/12 19:17:08 perlstalker Exp $

our $VERSION = '0.1.0';

use VUser::Log qw(:levels);
use VUser::ResultSet;
use VUser::SpamAssassin;
use VUser::SpamAssassin::SQL;
use VUser::Meta;
use VUser::ExtLib qw(:config);
use VUser::ExtLib::SQL;
use VUser::Extension;
use base qw(VUser::Extension);

our $log;
our $c_sec = 'Extension SpamAssassin::SQL::Userprefs';
our %meta;
our $db;
my $dsn;
my $username;
my $password;

sub c_sec { return $c_sec; };
sub meta { return %meta; };

sub depends { qw(SpamAssassin::SQL); }

sub init {
    my $eh = shift;
    my %cfg = @_;
    
    if ( defined $main::log ) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new( \%cfg, 'vuser' );
    }
    
    %meta = VUser::SpamAssassin::SQL::meta();
    
    $dsn      = strip_ws( $cfg{$c_sec}{'dsn'} );
    $username = strip_ws( $cfg{$c_sec}{'username'} );
    $password = strip_ws( $cfg{$c_sec}{'password'} );

    if ($dsn) {    
        $db = VUser::ExtLib::SQL->new(\%cfg,
            		      {'dsn' => $dsn,
			 	           'user' => $username,
				           'password' => $password,
				           'macros' => { 'u' => 'username',
						      'o' => 'option',
						      'v' => 'value'
						      }
				           });
    } else {
        $db = VUser::SpamAssassin::SQL::db();
    }
    
    if (not defined $db) {
        $log->log(LOG_ERROR, "Unable to connect to database.");
        die "Unable to connect to database\n";
    }
    
    $eh->register_task('sa', 'delall', \&sa_delall);
    $eh->register_task('sa', 'add', \&do_sql);
    $eh->register_task('sa', 'mod', \&do_sql);
    $eh->register_task('sa', 'del', \&do_sql);
    $eh->register_task('sa', 'show', \&sa_show);
    
    # Email
    $eh->register_keyword('email');

    # Email-del: When an email is deleted, we need to remove all their
    # settings as well.
    $eh->register_action('email', 'del');
    $eh->register_task('email', 'del', \&sa_delall);
}

sub unload {};

sub do_sql {
    my ( $cfg, $opts, $action, $eh ) = @_;

    my $query;

    if ( $action eq 'add' ) {
        $query = 'add_query';
    } elsif ( $action eq 'del' ) {
        $query = 'del_query';
    } elsif ( $action eq 'mod' ) {
        $query = 'mod_query';
    }

    my $sql = strip_ws( $cfg->{$c_sec}{$query} );

    if (not $sql) {
        $log->log(LOG_WARN, "No query specified for $query. Skipping.");
        return;
    }

    my $sth = $db->execute( $opts, $sql );
    $sth->finish;
}

sub sa_delall {
    my ( $cfg, $opts, $action, $eh ) = @_;

    my $query = 'delall_query';
    my $sql = strip_ws( $cfg->{$c_sec}{$query} );

    if (not $sql) {
        $log->log(LOG_WARN, "No query specified for $query. Skipping.");
        return;
    }

    my $sth = $db->execute( $opts, $sql );
    $sth->finish;
}

sub sa_show {
    my ( $cfg, $opts, $action, $eh ) = @_;


    my $query = 'show_query';
    my $sql = strip_ws( $cfg->{$c_sec}{$query} );

    if (not $sql) {
        $log->log(LOG_WARN, "No query specified for $query. Skipping.");
        return;
    }

    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'username'});
    $rs->add_meta($meta{'value'});
    $rs->add_meta($meta{'option'});

    my $sth = $db->execute( $opts, $sql );
    
    my @results;
    while (@results = $sth->fetchrow_array()) {
        $rs->add_data([@results[0..2]]);
    }
    
    $sth->finish;
    return $rs;
}

1;

__END__

=head1 NAME

VUser::SpamAssassin::SQL::Userprefs - vuser SpamAssassin SQL user preferences extension

=head1 DESCRIPTION

VUser::SpamAssassin::SQL::Userprefs is an extension to vuser that allows one to view and modify
users' SpamAssassin preferences in an SQL database.

=head1 CONFIGURATION

 [vuser]
 extensions = SpamAssassin::SQL::Userprefs
 
 [Extension SpamAssassin::SQL::Userprefs]
 # User scores database username and password.
 # The DSN's here are in the same format as defined in the sql/README*
 # files in the SpamAssassin package.
 # This user needs select, insert and delete permissions.
 # If the dsn is not set, the connection from SpamAssassin::SQL.
 #dsn = dbi:mysql:localhost
 #username = sa
 #password = a-password

 ## SQL Queries
 # Here you define the queries used to add, modify and delete users and
 # attributes. There are a few predefined macros that you can use in your
 # SQL. The values will be quoted and escaped before being inserted into
 # the SQL.
 #  %u => username
 #  %o => option
 #  %v => value
 #  %-option => This will be replaced by the value of --option passed in
 #              when vuser is run.
 # Add a preference to the database
 add_query = INSERT into userpref set username = %u, preference = %o, value = %v
 
 # Modify a value in the database
 mod_query = UPDATE userpref set value = %v where username = %u and preference = %o
 
 # Delete a preference for a user
 del_query = DELETE from userpref where username = %u and preference = %o
 
 # Delete all preferences for a user
 delall_query = DELETE from userpref where username = %u

 # Get the user's preferences
 # Fixed columns:
 #   1 username
 #   2 preference
 #   3 value
 show_query = SELECT username,preference,value from userpref where username = %u

=head1 BUGS

VUser::SA::SQL::Userprefs doesn't handle preferences with multiple values
(ex. blacklist_from) very well. It can't add them and attempting to modify
them will change all of the values unless you contruct the query very
carefully.

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
