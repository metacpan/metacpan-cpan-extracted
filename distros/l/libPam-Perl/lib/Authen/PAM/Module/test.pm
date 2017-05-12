package Authen::PAM::Module::test;

use strict;
use warnings;
use Authen::PAM::Module;
use Carp;
#use DBI;

our @ISA = qw(Authen::PAM::Module);

sub authenticate {
	my $self=shift;
	print $self->{user}."\n";
	my @ret=$self->conv(
		[PROMPT_ECHO_ON=>"test:"],
		[PROMPT_ECHO_ON=>"test:"],
		[PROMPT_ECHO_OFF=>"test:"],
		[ERROR_MSG=>"test:"],
		[TEXT_INFO=>"test:"],
	);
	print "@ret\n";
	print join ' ',map {$_+0} @ret;
	print "\n";
	$self->{env}{test}="a";
	$self->{env}{tesl}="a";
	foreach(keys %{$self->{env}}){
		my$a=$self->{env}{$_};
		$a="UNDEF" unless defined $a;
		print "$_ = ".$a."\n";
	}
	foreach(keys %{$self->{item}}){
		my$a=$self->{item}{$_};
		$a="UNDEF" unless defined $a;
		print "$_ = ".$a."\n";
	}
	print $ENV{PATH};
	print "\n";
	#print Authen::PAM::Module::_item::FIRSTKEY(\$self);
	warn;
	#die;
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
