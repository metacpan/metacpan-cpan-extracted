package Authen::PAM::Module::BBS;

use strict;
use warnings;
use Authen::PAM::Module;
use Carp;
#use DBI;

our @ISA = qw(Authen::PAM::Module);

sub authenticate {
	my $self=shift;
	my $flags=shift;
	my $name=shift;

	if(defined $_[0] && $_[0] eq 'chkuser'){
		return "SUCCESS" if getpwnam($self->{user});
		return "IGNORE";
	}
	#print $self->{user}."\n";
	print join ' ', @_;
	print $ENV{PATH};
	return "SUCCESS";
	return "IGNORE";
}
sub acct_mgmt {
	warn "@_";
	return "SUCCESS";
}
sub open_session {
	warn "@_";
	return "SUCCESS";
}
sub setcred {
	warn "@_";
	return "SUCCESS";
}
sub close_session {
	warn "@_";
	return "SUCCESS";
}
1;
