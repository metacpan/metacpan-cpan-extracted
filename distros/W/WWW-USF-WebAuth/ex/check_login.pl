#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings 'all';

# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.000';

# MODULES
use Const::Fast qw(const);
use Getopt::Long::Descriptive;
use WWW::USF::WebAuth 0.002;

# CONSTANTS
const my $EXIT_SUCCESS => 0;
const my $EXIT_ERROR_UNKNOWNSERVICE => 19;
const my $EXIT_ERROR_IOPROMPTER => 20;
const my $EXIT_ERROR_BADPASSWORD => 30;
const my %SERVICE => (
	Blackboard_Learn => 'https://learn.usf.edu/webapps/login/',
	MyUSF_Portal     => 'https://usfsts.usf.edu/Login.aspx',
	UNA              => 'https://netid.usf.edu/una/',
);

# COMMAND LINE OPTIONS
my ($opt, $usage) = describe_options(
	'%c %o',
	['netid|username|u:s', 'the NetID to authenticate with'],
	['password|p:s', 'the NetID password'],
	['service:s', 'a service to authenticate for (some notifications are only present with a service)'],
	[],
	['verbose|v', 'print extra information'],
	['help', 'print usage message and exit'],
);

if ($opt->help) {
	# Print the help message and exit successfully
	print $usage->text;
	exit $EXIT_SUCCESS;
}

if ($opt->_specified('service') && !exists $SERVICE{$opt->service}) {
	say 'Unknown service specified; known options are: ', join q{ }, keys %SERVICE;
	exit $EXIT_ERROR_UNKNOWNSERVICE;
}

# Get the NetID and password
my $netid = $opt->_specified('netid') ? $opt->netid : prompt_for('NetID');
my $password = $opt->_specified('password') ? $opt->password : prompt_for('Password', 1);

# Make the webauth object
my $webauth = WWW::USF::WebAuth->new(
	netid    => $netid,
	password => $password,
);

# Attempt to authenticate
say 'Authenticating with WebAuth' if $opt->verbose;
my $response = $webauth->authenticate(
	($opt->_specified('service') ? (service => $SERVICE{$opt->service}) : ()),
);

if ($response->has_notification) {
	# There is a notification to show the user
	say $response->notification;
}

if (!$response->is_success) {
	say 'The supplied NetID and password combination was incorrect.';
	exit $EXIT_ERROR_BADPASSWORD;
}
else {
	say 'NetID and password match';
}

if ($response->has_ticket_granting_cookie && $opt->verbose) {
	say 'Your ticket granting cookie is ', $response->ticket_granting_cookie;
}

exit $EXIT_SUCCESS;

# FUNCTIONS
sub prompt_for {
	my ($prompt, $hide_input) = @_;

	if (!eval 'use IO::Prompter (); 1') {
		say "When IO::Prompter is not installed, please use the command-line options: $@";
		exit $EXIT_ERROR_IOPROMPTER;
	}

	# Arguments to prompt
	my @prompt_args = "$prompt:";

	if ($hide_input) {
		push @prompt_args, -echo => q{*};
	}

	# Prompt for the input
	my $input = IO::Prompter::prompt(@prompt_args);

	# Force the input into a string
	return "$input";
}
