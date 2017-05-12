package VUser::Auth::SQLite;
use warnings;
use strict;

# Copyright 2005 Randy Smith
# $Id: SQLite.pm,v 1.5 2006-01-04 21:57:48 perlstalker Exp $

our $REVISION = (split (' ', '$Revision: 1.5 $'))[1];
our $VERSION = "0.3.0";

sub revision { return $REVISION; }
sub version { return $VERSION; }

use DBI;
use VUser::ACL qw/:consts/;

my $dbh = undef;
my $table = 'auth';

sub init
{
    my $acl = shift;
    my $cfg = shift;

    $acl->register_auth(\&auth_user);

    my $db = VUser::ExtLib::strip_ws($cfg->{'ACL SQLite'}{'file'});
    if (not -e $db) {
	$dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '');
	# Database didn't exist so we need to create it.
	my $sql = "create table $table (";
	$sql .= " user varchar(128) not null primary key";
	$sql .= ", ip varchar(20)";
	$sql .= ", password varchar(40) not null";
	$sql .= ")";
	$dbh->do($sql) or die "DB Error: ".$dbh->errstr;
    } else {
	$dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '');
    }
}

sub auth_add
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $sql = "insert into $table ";
    $sql .= " values (?, ?, ?)";

    my $sth = $dbh->prepare($sql) or die "DB Error: ".$dbh->errstr;
    $sth->execute($opts->{'user'},
		  defined $opts->{'ip'} ? $opts->{'ip'} : '',
		  $opts->{'password'})
	or die "DB Error: ".$sth->errstr;
}

sub auth_del
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $sql = "delete from $table where user = ?";
    my $sth = $dbh->prepare($sql) or die "DB Error: ".$dbh->errstr;
    $sth->execute($opts->{'user'})
	or die "DB Error: ".$sth->errstr;
}

sub auth_user
{
    my ($cfg, $user, $pass, $ip) = @_;

    my $sql = "select * from $table where user = ?";
    my $sth = $dbh->prepare($sql) or die "DB Error: ".$dbh->errstr;
    $sth->execute($user) or die "DB Error: ".$dbh->errstr;

    my $res = $sth->fetchrow_hashref;
    if (not defined $res) {
	return UNKNOWN();
    } elsif ($pass eq $res->{password}) {
	return ALLOW();
    } else {
	return DENY();
    }
    
}

sub auth_get
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $user = $opts->{user} || '%';

    my $sql = "select * from $table where user like ?";
    my $sth = $dbh->prepare($sql) or die 'DB Error: '.$dbh->errstr;
    $sth->execute($user) or die 'DB Error: '.$dbh->errstr;

    my @users = ();
    
    my $res;
    while (defined ($res = $sth->fetchrow_hashref)) {
	push @users, {user => $res->{user},
		      password => $res->{password},
		      ip => $res->{ip}};
    }

    return @users;
}

1;

__END__

=head1 NAME

VUser::Auth::SQLite - SQLite backend for internal authentication

=head1 DESCRIPTION

B<Note:> Does not support limiting access by IP address.

=head1 METHODS

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>

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
