#!/usr/bin/perl -w
use strict;
use Unix::SearchPathGuess ':all';

# load Test
use Test;
BEGIN { plan tests => 3 };

# debugging
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

#------------------------------------------------------------------------------
# note if this test is being run in an acceptable operating system
#
my ($bad_os);

if ( ($^O =~ m|MSWin32|si) || ($^O =~ m|cygwin|si) )
	{ $bad_os = 1 }
else
	{ $bad_os = 0 }
#
# note if this test is being run in an acceptable operating system
#------------------------------------------------------------------------------


# start by setting path to empty string
$ENV{'PATH'} = '';


#------------------------------------------------------------------------------
# set_local_path
#
if (1) {
	# set local path in a block
	do {
		local $ENV{'PATH'} = search_path_guess();
		
		# path should not be an empty string
		ok(length $ENV{'PATH'});
	};
	
	# path should be an empty string
	ok($ENV{'PATH'} eq '');
}
#
# set_local_path
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# look for ls program
#
if (1) {
	# if not in Unixish OS, just output OK
	# KLUDGE: Somehow I couldn't get skip() to work properly. See
	# http://www.perlmonks.org/index.pl/?node_id=1111675 for a description of
	# the problem. Please feel free to contact me with the solution.
	if ($bad_os) {
		ok(1);
	}
	
	# else run the test
	else {
		my $ls = cmd_path_guess('ls');
		ok($ls);
	}
}
#
# look for ls program
#------------------------------------------------------------------------------
