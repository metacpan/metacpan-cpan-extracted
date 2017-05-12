#!/usr/bin/perl -w
use strict;
use Unix::Mgt;
use Test::More;
use Unix::SearchPathGuess ':all';

# go to test directory
BEGIN {
	use File::Spec;
	use File::Basename();
	my $thisf = File::Spec->rel2abs($0);
	my $thisd = File::Basename::dirname($thisf);
	chdir($thisd);
}

# load home-grown test libraries 
require './test-lib.pm';
require './module-lib.pm';

# tools for debugging
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;


#------------------------------------------------------------------------------
# check if this test is being run in an acceptable operating system
#
my ($bad_os);

# guess if this is Windows or cygwin
if ( ($^O =~ m|MSWin32|si) || ($^O =~ m|cygwin|si) )
	{ $bad_os = 1 }
else
	{ $bad_os = 0 }

# if this isn't an OS that this module supports, don't run any tests
if ($bad_os)
	{ plan skip_all => 'This module irrelevant on Windows' }
else
	{ plan tests => 15 }

#
# check if this test is being run in an acceptable operating system
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# existence of necessary external commands
#
do {
	# if we have pw command, set one test as ok and skip two more
	if (Unix::Mgt->use_bsd) {
		ok(cmd_path_guess('pw'), "file exists: pw");
		
		SKIP: {
			skip('adduser, usermod and groupadd irrelevent on this system', 2);
		}
	}
	
	# else look for adduser, usermod and groupadd
	else {
		foreach my $cmd (qw{adduser usermod groupadd}) {
			ok(cmd_path_guess($cmd), "file exists: $cmd");
		}
	}
};
#
# existence of necessary external commands
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= Unix::Mgt::User->get
#
if (1) { ##i
	my ($user);
	my $name = 'Unix::Mgt::User->get';
	
	# attempt to create user object without a user name fails
	$user = Unix::Mgt::User->get();
	mgt_err(
		"$name: attempt to create user object without a user name fails, \$err_id",
		'missing-user-name',
	);
	
	bool_check(
		"$name: attempt to create user object without a user name fails, boolean",
		$user,
		0,
	);
	
	# attempt to create user object with nonexistent name fails
	$user = Unix::Mgt::User->get('djdjdjdjdjdjd');
	mgt_err("$name: attempt to create user object with nonexistent name fails, \$err_id", 'do-not-have-user');
	bool_check("$name: attempt to create user object with nonexistent name fails, boolean", $user, 0);
	
	# create user object with existent name
	$user = Unix::Mgt::User->get('root');
	mgt_err("$name: create user object with existent name, \$err_id", undef);
	bool_check("$name: create user object with existent name, boolean", $user, 1);
}
#
# Unix::Mgt::User->get
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= Unix::Mgt::Group->get()
#
if (1) { ##i
	my ($group);
	my $name = 'Unix::Mgt::User->get';
	
	##- attempt to create group object without a user name fails
	$group = Unix::Mgt::Group->get();
	mgt_err("$name: attempt to create group object without a user name fails, \$err_id", 'missing-group-name');
	bool_check("$name: attempt to create group object without a user name fails, boolean", $group, 0);
	
	##- attempt to create group object with nonexistent name fails
	$group = Unix::Mgt::Group->get('djdjdjdjdjdjd');
	mgt_err("$name: attempt to create group object with nonexistent name fails, \$err_id", 'do-not-have-group');
	bool_check("$name: attempt to create group object with nonexistent name fails, boolean", $group, 0);
	
	##- create group object with existent name
	$group = Unix::Mgt::User->get('root');
	mgt_err("$name: create group object with existent name, \$err_id", undef);
	bool_check("$name: create group object with existent name, boolean", $group, 1);
}
#
# Unix::Mgt::Group->get()
#------------------------------------------------------------------------------


