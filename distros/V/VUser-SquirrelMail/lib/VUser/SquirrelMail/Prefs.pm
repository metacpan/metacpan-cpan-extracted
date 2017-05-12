package VUser::SquirrelMail::Prefs;
use warnings;
use strict;

# Copyright 2005 Randy Smith
# $Id: Prefs.pm,v 1.5 2007/02/12 21:40:26 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.5 $'))[1];
our $VERSION = "0.1.1";

use VUser::Meta;
use VUser::ResultSet;
use VUser::Extension;
push @ISA, 'VUser::Extension';

my $csec = 'Extension SquirrelMail::Prefs'; # config section

my $dbh = undef;

our %meta = ('username' => VUser::Meta->new(name => 'username',
					   type => 'string',
					   description => 'User name'),
	    'option' => VUser::Meta->new (name => 'option',
					  type => 'string',
					  description => 'SquirrelMail option'),
	    'value' => VUser::Meta->new (name => 'value',
					 type => 'string',
					 description => 'Value for option')
	    );

sub meta { return %meta; }

sub config_sample
{
    my $fh;
    my $cfg = shift;
    my $opts = shift;

    if (defined $opts->{file}) {
	open ($fh, ">".$opts->{file})
	    or die "Can't open '".$opts->{file}."': $!\n";
    } else {
	$fh = \*STDOUT;
    }

    print $fh <<'CONFIG';
[Extension SquirrelMail::Prefs]
# Can be mysql, pgsql, none
db type = mysql

# Host where the DB is
db host = localhost

# The name of the squirrelmail database
db name = squirrelmail

# The name of the preferences table
prefs table = userprefs

# Username and password for the database.
# Note: This user required select, insert, update and delete perms on the
# SquirrelMail userprefs table.
db user = squirrelmail
db password = secret

# Location of SquirrelMail data files
data dir = /usr/local/squirrelmail/data

CONFIG
    if (defined $opts->{file}) {
	close $fh;
    }

}

sub init
{
    my $eh = shift;
    my %cfg = @_;

    my $db_type = VUser::ExtLib::strip_ws($cfg{$csec}{'db type'});
    if ($db_type and $db_type ne 'none') {
	my $dsn = "dbi:$db_type:";
	my $db_name = VUser::ExtLib::strip_ws($cfg{$csec}{'db name'});
	my $db_host = VUser::ExtLib::strip_ws($cfg{$csec}{'db host'});
	if ($db_type eq 'mysql') {
	    $dsn .= "database=$db_name";
	    $dsn .= ";host=$db_host" if $db_host;
	} else {
	    # Semi-reasonable default if we don't know what the DB is.
	    $dsn .= "$db_name";
	}
	my $user = VUser::ExtLib::strip_ws($cfg{$csec}{'db user'});
	my $pass = VUser::ExtLib::strip_ws($cfg{$csec}{'db password'});
	$dbh = DBI->connect ($dsn, $user, $pass,
			     { RaiseError => 1, AutoCommit => 0})
	    or die "Database error: ".DBI->errstr;
    }

    $eh->register_keyword('smprefs', 'Manage SquirrelMail user preferences');

    # add
    $eh->register_action('smprefs', 'add', 'Add a preference for the user');
    $eh->register_option('smprefs', 'add', $meta{'username'}, 1);
    $eh->register_option('smprefs', 'add', $meta{'option'}, 1);
    $eh->register_option('smprefs', 'add', $meta{'value'}, 1);
    $eh->register_task('smprefs', 'add', \&smprefs_add);

    # mod
    $eh->register_action('smprefs', 'mod', 'Change a user\'s preferences');
    $eh->register_option('smprefs', 'mod', $meta{'username'}, 1);
    $eh->register_option('smprefs', 'mod', $meta{'option'}, 1);
    $eh->register_option('smprefs', 'mod', $meta{'value'}, 1);
    $eh->register_task('smprefs', 'mod', \&smprefs_mod);

    # del
    $eh->register_action('smprefs', 'del', 'Delete a preference for a user');
    $eh->register_option('smprefs', 'del', $meta{'username'}, 1);
    $eh->register_option('smprefs', 'del', $meta{'option'}, 1);
    $eh->register_task('smprefs', 'del', \&smprefs_del);

    # show
    $eh->register_action('smprefs', 'show', 'Show the preference/user combination');
    $eh->register_option('smprefs', 'show', $meta{'username'}, 0);
    $eh->register_option('smprefs', 'show', $meta{'option'}, 0);
    $eh->register_task('smprefs', 'show', \&smprefs_show);

    # delall: Delete all options
    $eh->register_action('smprefs', 'delall', 'Delete all options for a user');
    $eh->register_option('smprefs', 'delall', $meta{'username'}, 1);
    $eh->register_task('smprefs', 'delall', \&smprefs_delall);

    # Email
    $eh->register_keyword('email');

    $eh->register_action('email', 'del');
    $eh->register_task('email', 'del', \&smprefs_delall);
}

sub unload {}

sub smprefs_add
{
    my ($cfg, $opts, $action, $eh) = @_;

    if (defined $dbh) {
	my $table = VUser::ExtLib::strip_ws($cfg->{$csec}{'prefs table'});
	my $sql = "Insert into $table set user = ?, prefkey = ?, prefval = ?";
	my $sth = $dbh->prepare($sql)
	    or die "Database error: ".$dbh->errstr."\n";
	$sth->execute($opts->{username},
		      $opts->{option},
		      $opts->{value})
	    or die "Database error: ".$sth->errstr."\n";
    } else {
	# File-based here
    }
    return undef;
}

sub smprefs_mod
{
    my ($cfg, $opts, $action, $eh) = @_;

    if (defined $dbh) {
	
    } else {
	# file-based here
    }

    return undef;
}

sub smprefs_show
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $user = $opts->{username} if defined $opts->{username};
    my $option = $opts->{option} if defined $opts->{option};

    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'username'});
    $rs->add_meta($meta{'option'});
    $rs->add_meta($meta{'value'});

    if (defined $dbh) {
	my $table = VUser::ExtLib::strip_ws($cfg->{$csec}{'prefs table'});
	my $sql = "select user,prefkey, prefval from $table";

	my @params = ();
	if (defined $user and defined $option) {
	    $sql .= " where user = ? and prefkey = ?";
	    @params = ($user, $option);
	} elsif (not defined $option) {
	    $sql .= " where user = ?";
	    @params = ($user);
	} elsif (not defined $user) {
	    $sql .= " where prefkey = ?";
	    @params = ($option);
	}

	my $sth = $dbh->prepare($sql)
	    or die "Database error: ".$dbh->errstr."\n";
	$sth->execute(@params)
	    or die "Database error: ".$sth->errstr."\n";

	my @res;
	while (@res = $sth->fetchrow_array) {
	    $rs->add_data([@res]);
	}
    } else {
	# File based...
    }

    return $rs;
}

sub smprefs_del{}

sub smprefs_delall
{
    my $cfg = shift;
    my $opts = shift;

    my $user = $opts->{username};

    # The email extension uses 'account' instead of 'username'
    $user = $opts->{account} if not $user;

    if (defined $dbh) {
	my $table = VUser::ExtLib::strip_ws($cfg->{$csec}{'prefs table'});
	my $sql = "delete from $table where user = ?";
	my $sth = $dbh->prepare($sql)
	    or die "Database error: ".$dbh->errstr."\n";
	$sth->execute($opts->{username})
	    or die "Database error: ".$sth->errstr."\n";
    } else {
	# File-based here
    }
    return undef;
}

1;

__END__

=head1 NAME

VUser::SquirrelMail::Prefs - Extension for managing SquirrelMail preferences.

=head1 DESCRIPTION

It is assumed that this module will be used primarily when using a database
to store SquirrelMail settings. File based configuration is not supported
at this time but will probably be added at some point in the future.

=head1 CONFIGURATION

 [vuser]
 extensions = SquirrelMail::Prefs

 [Extension SquirrelMail::Prefs]
 # Can be mysql, pgsql, none
 db type = mysql
 
 # Host where the DB is
 db host = localhost
 
 # The name of the squirrelmail database
 db name = squirrelmail
 
 # The name of the preferences table
 prefs table = userprefs
 
 # Username and password for the database.
 # Note: This user required select, insert, update and delete perms on the
 # SquirrelMail userprefs table.
 db user = squirrelmail
 db password = secret
 
 # Location of SquirrelMail data files
 data dir = /usr/local/squirrelmail/data

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
