#!/usr/bin/perl

########################################################################
# This is a very simple addusers script. Tweak to your needs
########################################################################
# In order to run this script:
#  1)you will need to setup your database tables. Example database
#    scheme's are available in the examples/ subdirectory.
#  4)change the globals below to match your situation.
#
########################################################################

my $db_user = 'test';
my $db_pass = '';
my $db_dbase = 'test';
my $db_driver = 'mysql';
my $db_host = 'localhost';

use strict;
use DBI;
use Digest::MD5 ();

my $datasource = join(':', ('dbi',$db_driver,$db_dbase,$db_host));
my $dbh = DBI->connect( $datasource, $db_user, $db_pass )
	or die "Can't connect to $db_driver dbase $db_dbase on $db_host: $DBI::errstr\n";


my @users = (
	[1,'admin','adminpasswd','0'], # admin account
	[2,'test1','testpasswd','0'], # readonly account
	[3,'test2','testpasswd','0'], # writeonly account
	[4,'test3','testpasswd','0'], # readwrite account
	[5,'test4','testpasswd','0'], # enabled, but no group access
	[6,'test5','testpasswd','0'], # enabled, but no group entries
	[7,'test6','testpasswd','1'], # disabled account
	);
my @groups = (
	[1,'admin'], # admin group
	[2,'db1'], # some other group
	);
my %user_groups = (
	1	=> [	# admin uid
		[1,'3'], # group 1, rwbit 3 (rw)
		[2,'1'], # group 2, rwbit 1 (r)
		],
	2	=> [ [2,1] ], # test1 uid, rwbit 1 (r)
	3	=> [ [2,2] ], # test2 uid, rwbit 2 (w)
	4	=> [ [2,3] ], # test3 uid, rwbit 3 (rw)
	5	=> [ [2,0] ], # test4 uid, rwbit 0 ([no access])
	6	=> [       ], # test5 uid, no group entries
	7	=> [ [2,1] ], # test6 uid, rwbit 1 (r)
	);

# Add users
my $adduser = $dbh->prepare("INSERT INTO Users (uid,login,passwd,Disabled) VALUES (?,?,?,?)")
	or die "can't prepare new user statement: $DBI::errstr";
foreach my $user (@users)
{
	$user->[2] = Digest::MD5::md5_base64($user->[2]);
	$adduser->execute(@{$user}) or die "can't insert user: $DBI::errstr";
}
$adduser->finish;

# Add groups
my $addgroup = $dbh->prepare("INSERT INTO Groups (gid,Name) VALUES (?,?)")
	or die "can't prepare new user statement: $DBI::errstr";
foreach my $group (@groups)
{
	$addgroup->execute(@{$group}) or die "can't insert group: $DBI::errstr";
}
$addgroup->finish;

# Put users into groups
my $add_ug = $dbh->prepare("INSERT INTO UserGroups (uid,gid,accessbit) VALUES (?,?,?)")
	or die "can't prepare new usergroup statement: $DBI::errstr";
foreach my $uid (keys %user_groups)
{
	foreach my $access ( @{$user_groups{$uid}} )
	{
		$add_ug->execute($uid, @{$access}) or die "can't insert usergroup: $DBI::errstr";
	}
}
$add_ug->finish;

$dbh->disconnect();


