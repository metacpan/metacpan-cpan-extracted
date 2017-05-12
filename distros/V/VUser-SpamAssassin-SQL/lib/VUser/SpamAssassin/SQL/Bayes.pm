package VUser::SpamAssassin::SQL::Bayes;
use warnings;
use strict;

# Copyright (c) 2007 Randy Smith <perlstalker@vuser.org>
# $Id: Bayes.pm,v 1.2 2007/04/12 19:17:08 perlstalker Exp $

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
    
    # Email
    $eh->register_keyword('email');

    # Email-del: When an email is deleted, we need to remove all their
    # settings as well.
    $eh->register_action('email', 'del');
    $eh->register_task('email', 'del', \&sa_delall);
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

1;

__END__

=head1 NAME

VUser::SpamAssassin::SQL::Bayes - vuser SpamAssassin SQL Bayesian filter extension

=head1 DESCRIPTION

VUser::SpamAssassin::SQL::Bayes is an extension to vuser that allows one to view and modify
users' SpamAssassin Bayesian data in an SQL database. For now only deleting the data is supported.

=head1 CONFIGURATION

 [vuser]
 extensions = SpamAssassin::SQL::Bayes
 
 [Extension SpamAssassin::SQL::Bayes]
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
 # Delete all preferences for a user
 delall_query = DELETE from bayes where username = %u

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
