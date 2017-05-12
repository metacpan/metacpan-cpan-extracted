package VUser::SquirrelMail::Prefs::SQL;
use warnings;
use strict;

# Copyright 2007 Randy Smith <perlstalker@vuser.org>
# $Id: SQL.pm,v 1.2 2007/04/10 21:17:22 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.2 $'))[1];
our $VERSION = "0.1.1";

use VUser::Meta;
use VUser::ResultSet;
use VUser::ExtLib qw(:config);
use VUser::ExtLib::SQL;
use VUser::Log qw(:levels);
use VUser::Extension;
push @ISA, 'VUser::Extension';

my $csec = 'Extension SquirrelMail::Prefs::SQL'; # config section

my $extlib = undef;
my $log;

our %meta;

sub depends { qw(SquirrelMail::Prefs); }

sub init
{
    my $eh = shift;
    my %cfg = @_;

    %meta = VUser::SquirrelMail::Prefs::meta();
    
    if ( defined $main::log ) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new( \%cfg, 'vuser' );
    }

    my $dsn = strip_ws($cfg{$csec}{dsn});
	
    if (not defined $dsn) { 
	
	my $db_type = VUser::ExtLib::strip_ws($cfg{$csec}{'db type'});
	$dsn = "dbi:$db_type:";
	if ($db_type and $db_type ne 'none') {
	    
	    my $db_name = VUser::ExtLib::strip_ws($cfg{$csec}{'db name'});
	    my $db_host = VUser::ExtLib::strip_ws($cfg{$csec}{'db host'});
	    $dsn .= "$db_host:";
	    if ($db_type eq 'mysql') {
		$dsn .= "database=$db_name";
		$dsn .= ";host=$db_host" if $db_host;
	    } else {
		# Semi-reasonable default if we don't know what the DB is.
		$dsn .= "$db_name";
	    }
	}
    }
	
    my $user = VUser::ExtLib::strip_ws($cfg{$csec}{'db user'});
    my $pass = VUser::ExtLib::strip_ws($cfg{$csec}{'db password'});
    
    $extlib = VUser::ExtLib::SQL->new(\%cfg,
				      {'dsn' => $dsn,
				       'user' => $user,
				       'password' => $pass,
				       'macros' => { 'u' => 'username',
						     'o' => 'option',
						     'v' => 'value'
						     }
				   });
			
    # smprefs|add
    $eh->register_task('smprefs', 'add', \&do_sql);
    
    # smprefs|mod
    $eh->register_task('smprefs', 'mod', \&do_sql);
    
    # smprefs|del
    $eh->register_task('smprefs', 'del', \&do_sql);
    
    # smprefs|show
    $eh->register_task('smprefs', 'show', \&smprefs_show);
    
    # smprefs|delall
    $eh->register_task('smprefs', 'delall', \&do_sql);
    
    # email|del
    $eh->register_task('email', 'del', \&email_del);
}

sub unload {};

sub do_sql {
    my ( $cfg, $opts, $action, $eh ) = @_;

    my $query;

    if ( $action eq 'add' ) {
        $query = 'addpref_query';
    } elsif ( $action eq 'del' ) {
        $query = 'delpref_query';
    } elsif ( $action eq 'mod' ) {
        $query = 'modpref_query';
    } elsif ( $action eq 'delall' ) {
        $query = 'delallpref_query';
    }

    my $sql = strip_ws( $cfg->{$csec}{$query} );

    if (not $sql) {
        $log->log(LOG_WARN, "No query specified for $query. Skipping.");
        return;
    }

    my $sth = $extlib->execute( $opts, $sql );
    $sth->finish;
}

sub smprefs_show
{
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $query;
    if ($opts->{'username'} and $opts->{'option'}) {
        $query = 'showuseropt_query';
    } elsif ($opts->{'username'}) {
        $query = 'showuser_query';
    } elsif ($opts->{'option'}) {
        $query = 'showopt_query';
    } else {
        $query = 'showall_query';
    }
    
    my $sql = strip_ws($cfg->{$csec}{$query});
    
    if (not $sql) {
        $log->log(LOG_WARN, "No query specified for $query. Skipping");
        return;
    }
    
    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'username'});
    $rs->add_meta($meta{'option'});
    $rs->add_meta($meta{'value'});
    
    my $sth = $extlib->execute($opts, $sql);
    my @res;
    while (@res = $sth->fetchrow_array()) {
        $rs->add_data([ @res[0..2] ]); 
    }
    $sth->finish;
    
    return $rs;
}

sub email_del
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $query = 'delallpref_query';
    my $sql = strip_ws( $cfg->{$csec}{$query} );

    if (not $sql) {
        $log->log(LOG_WARN, "No query specified for $query. Skipping.");
        return;
    }

    my $sth = $extlib->execute( $opts, $sql );
    $sth->finish;
}

1;

__END__

=head1 NAME

VUser::SquirrelMail::Prefs::SQL - Extension for managing SquirrelMail preferences in a SQL database.

=head1 DESCRIPTION

It is assumed that this module will be used primarily when using a database
to store SquirrelMail settings. File based configuration is not supported
at this time but will probably be added at some point in the future.

=head1 CONFIGURATION


 [vuser]
 extensions = SquirrelMail::Prefs::SQL

 [Extension SquirrelMail::Prefs::SQL]
 # Can be mysql, pgsql, none
 db type = mysql
 
 # Host where the DB is
 db host = localhost
 
 # The name of the squirrelmail database
 db name = squirrelmail
 
 # You may specify the DSN directly instead of having S::P::SQL guess it.
 # 'dns' overrides the 'db type', 'db host' and 'db name' settings above
 # dsn = dbi:mysql:localhost
 
 # Username and password for the database.
 # Note: This user required select, insert, update and delete perms on the
 # SquirrelMail userprefs table.
 db user = squirrelmail
 db password = secret
 
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
 
 # Add a preference
 addpref_query = Insert into userprefs set user = %u, prefkey = %o, prefval = %v
 
 # Delete a preference
 delpref_query = Delete from userprefs where user = %u, prefkey = %o
 
 # Modify a preference
 modpref_query = Update userprefs set prefkey = %v where user = %u, prefkey = %o
 
 # Delete all preferences for a user
 delallpref_query = Delete from userprefs where user = %u
 
 # Show queries. These must return these columns in order
 #  user name, preference name, preference value
 #
 # Get a single option for a user
 showuseropt_query = Select user,prefkey,prefval from userprefs where user = %u and prefkey = $o
 
 # Get a single option for all users
 showopt_query = Select user,prefkey,prefval from userprefs where prefkey = %o
 
 # Get all options for a user
 showuser_query = Select user,prefkey,prefval from userprefs where user = %u
 
 # Get all options for all users
 showall_query = Select user,prefkey,prefval from userprefs;
 
=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of VUser-SquirrelMail.
 
 VUser-SquirrelMail is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-SquirrelMail is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with VUser-SquirrelMail; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
