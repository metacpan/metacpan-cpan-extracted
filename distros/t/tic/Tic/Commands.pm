package Tic::Commands;

use strict;
use Tic::Common;
use vars ('@ISA', '@EXPORT');
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(create_alias remove_alias command_msg command_alias
					  command_unalias command_echo command_info command_login
					  command_quit command_buddylist command_default
					  command_undefault command_log command_timestamp command_who
					  command_timestamp command_sn);

my $state;

sub import {
	#debug("Importing from Tic::Commands");
	Tic::Commands->export_to_level(1,@_);
}

sub set_state {
	my $self = shift;
	#debug("Setting state for ::Commands");
	$state = shift;
}

sub create_alias {
	my ($alias, $cmd) = @_;
	$alias =~ s!^/!!;

	$state->{"aliases"}->{$alias} = $cmd;
}

sub remove_alias {
	my ($alias) = @_;

	undef($state->{"aliases"}->{$alias});
}

sub get_config { 
	my ($a) = @_;
  	return $state->{"config"}->{$a};
}

sub set_config { 
	my ($a,$b) = @_; 
	$state->{"config"}->{$a} = $b;
}

sub command_msg {
	$state = shift;
	my ($args) = @_;
	my $aim = $state->{"aim"};
	my ($sn, $msg) = split(/\s+/, $args, 2);
	
	$aim->send_im($sn, $msg);
	if (($state->{"logging"}->{"who_log"}->{$sn} == 1) || ($state->{"config"}->{"logging"} eq "all")) {
		prettylog($state,"out_msg", { sn => $sn, msg => $msg } );
	}
}

sub command_alias {
	$state = shift;
	my ($args) = @_;
	my ($alias, $cmd) = split(/\s+/, $args, 2);
	my $aliases = $state->{"aliases"};

	if ($alias =~ m/^$/) {
		if (scalar(keys(%{$aliases})) == 0) {
			out("There are no aliases set.");
		} else {
			out("Aliases:");
			foreach my $alias (keys(%{$aliases})) {
				next unless (defined($aliases->{$alias}));
				out("$alias => " . $aliases->{$alias});
			}
		}
		return;
	}

	if ($cmd =~ m/^$/) {
		if (defined($aliases->{$alias})) {
			out("$alias => " . $aliases->{$alias});
		} else {
			error("No such alias, \"$alias\"");
		}
	} else {
		create_alias($alias, $cmd);
	}
}

sub command_unalias {
	$state = shift;
	my ($args) = @_;
	my ($alias) = split(/\s+/, $args);

	if ($alias =~ m/^$/) {
		error("Unalias what?");
		return;
	}

	remove_alias($alias);
	out("Removed the alias \"/$alias\"");
}

sub command_echo {
	$state = shift;
	my ($args) = @_;
	out($args);
}

sub command_info {
	$state = shift;
	my ($args) = @_;
	my $aim = $state->{"aim"};
	my ($sn,$key) = split(/\s+/,$args);

	if ($sn eq '') {
		error("Invalid number of arguments to /info.");
		return;
	}

	if ($key eq '') {
		out("Fetching user info for $sn");
		$aim->get_info($sn);
	} else {
		out("State info for $sn");
		out("$key: " . $aim->buddy($sn)->{$key});
	}
}

sub command_login {
	$state = shift;
	my ($args) = @_;
	my $aim = $state->{"aim"};
	if ($args eq '-f') {
		login();
	} else {
		if ($aim->is_on()) {
			error("You are already logged in, use /login -f to force reconnection.");
		} else {
			login();
		}
	}
}

sub login {
	my ($user, $pass);
	$user = query("login: ");
	$pass = query("password: ", 1);
	$state->{"signingon"} = 1;
	$state->{"aim"}->signon($user,$pass);
}

sub command_quit {
	$state = shift;
	my ($args) = @_;
	my $aim = $state->{"aim"};
	error("Bye :)");
	$aim->signoff();
	exit;
}

sub command_buddylist {
	$state = shift;
	my ($args) = @_;
	my $aim = $state->{"aim"};

	foreach my $g ($aim->groups()) {
		out($g);
		foreach my $b ($aim->buddies($g)) {
			my $bud = $aim->buddy($b,$g);

			my $extra;
			if ($bud) {
				$extra .= " [MOBILE]" if $bud->{mobile};
				$extra .= " [TYPINGSTATUS]" if $bud->{typingstatus};
				$extra .= " [ONLINE]" if $bud->{online};
				$extra .= " [TRIAL]" if $bud->{trial};
				$extra .= " [AOL]" if $bud->{aol};
				$extra .= " [FREE]" if $bud->{free};
				$extra .= " [AWAY]" if $bud->{away};
				$extra .= " {".$bud->{comment}."}" if defined $bud->{comment};
				$extra .= " {{".$bud->{alias}."}}" if defined $bud->{alias};
				$extra .= " (".$bud->{extended_status}.")" if defined $bud->{extended_status};
			}

			out("$b ($extra)");
		}
	}
}

sub command_default {
	$state = shift;
	my ($args) = @_;
	my $aim = $state->{"aim"};
	($args) = split(/\s+/,$args);

	if ($args eq '') {
		if ($state->{"default"}) {
			out("Default target: " . $state->{"default"});
		} else {
			error("No default target yet");
		}
	} else {
		if ($aim->buddy("$args")) {
			$state->{"default"} = $args;
			out("New default target: $args");
		} elsif ($args eq ';') {
			if ($state->{"last_from"}) {
				$state->{"default"} = $state->{"last_from"};
				out("New default target: " . $state->{"default"});
			} else {
				error("No one has sent you a message yet... what are you trying to do?!");
			}
		} else {
			error("The buddy $args is not on your buddylist, I won't default to it.");
		}
	}
}

sub command_undefault {
	$state = shift;
	my ($args) = @_;
	out("Default target cleared.");
	undef($state->{"default"});
}

sub command_log {
	$state = shift;
	my ($args) = @_;

	if ($args eq "+") {
		set_config("logging", "all");
		out("Now logging all messages.");
	} elsif ($args eq "-") {
		set_config("logging", "off");
		out("Stopping all logging.");
	} elsif ($args eq "on") {
		set_config("logging", "on");
		out("Logging is now on.");
	} elsif ($args eq '') {
		set_config("logging", "off") unless (defined(get_config("logging")));
		my $logstate = get_config("logging");
		out("Logging: $logstate");
		if ($logstate =~ m/^only/) {
			my $who = get_config("who_log");
			my @wholog = grep($who->{$_} == 1, keys(%{$who}));
			out("Currently logging: " . join(", ", @wholog));
		}
	} else {
		set_config("logging", "only specified users");
		set_config("who_log", {}) unless defined(get_config("who_log"));

		foreach (split(/\s+/,$args)) {
			if (m/^-(.*)/) {
				get_config("who_log")->{$1} = undef;
				out("Stopped logging $1");
			} elsif (m/^\+?(.+)/) {
				get_config("who_log")->{$1} = 1;
				out("Logging for $1 started");
			}
		}
	}

}

sub command_timestamp {
	$state = shift;
	my ($args) = @_;

	if ($args =~ m/^(yes|on|plz)$/i) {
		$state->{"timestamp"} = 1;
		prettyprint($state, "generic_status", { msg => "Timestamps are now on." } );
	} elsif ($args =~ m/^(no|off)$/i) {
		$state->{"timestamp"} = 0;
		prettyprint($state, "generic_status", { msg => "Timestamps are now off." } );
	} elsif ($args =~ m/^$/) {
		my $status = ( ($state->{"timestamp"}) ? "on" : "off" );
		prettyprint($state, "generic_status", { msg => "Timestamps are $status." } );
	} else {
		prettyprint($state, "error_generic", "Invalid parameter to /timestamp");
	}

}

sub command_sn {
	$state = shift;
	my ($args) = @_;

	my $foo = $state->{"aim"}->buddy($args);
	out("Name: $foo / " . $foo->{"screenname"});
}

sub command_who {
	$state = shift;
	my ($args) = @_;
	my $aim = $state->{"aim"};

	foreach my $g ($aim->groups()) {
		out($g);
		my @buddies = $aim->buddies($g);
		foreach my $b (sort(compare($a,$b),@buddies)) {
			my $bud = $aim->buddy($b,$g);
			next unless (defined($bud));
			my $e;
			$e .= "offline" unless ($bud->{"online"});
			$e ||= "online, ";
			$e .= "away, " if ($bud->{"away"});
			$e .= "idle, " if ($bud->{"idle"});
			$e =~ s/, $//;

			out("    $b ($e)");

		}
	}
}

sub compare {
	local $a = buddyscore($a);
	local $b = buddyscore($b);
	return $a <=> $b;
}

sub buddyscore {
	my $buddy = shift;
	$buddy = $state->{"aim"}->buddy($buddy);
	my $sum = 0;
	return -11 if (!defined($buddy));

	$sum += 10 if ($buddy->{online});
	$sum -= 10 unless ($buddy->{online}); 
	$sum -= 5 if ($buddy->{away});
	$sum -= 3 if ($buddy->{idle});
	#out($buddy->{"screenname"} . " = $sum");

	return $sum;
}

1;
