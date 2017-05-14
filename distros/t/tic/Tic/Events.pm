package Tic::Events;

use strict;
use Tic::Common;
use vars ('@ISA', '@EXPORT');
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( event_admin_error          event_chat_closed
						event_admin_ok             event_chat_im_in
						event_buddy_in             event_connection_changed
						event_buddy_info           event_error
						event_buddy_out            event_evil
						event_buddylist_error      event_im_in
						event_buddylist_ok         event_im_ok
						event_chat_buddy_in        event_rate_alert
						event_chat_buddy_out       event_signon_done );

my $state;

sub import {
	#debug("Importing from Tic::Events");
	Tic::Events->export_to_level(1,@_);
}

sub set_state {
	my $self = shift;
	#debug("Setting state for ::Events");
	$state = shift;
}

sub event_admin_error {
	my ($aim, $reqtype, $error, $errurl) = @_;
}

sub event_admin_ok {
	my ($aim, $reqtype) = @_;
}

sub event_buddy_in {
	my ($aim, $sn, $group, $data) = @_;
	if (!defined($state->{"buddylist"}->{$sn})) {
		prettyprint($state, "buddy_online", { sn => $sn, group => $group } );
	} else {
		my $b = $state->{"buddylist"}->{$sn};
		if ($b->{"away"} != $data->{"away"}) {
			if ($data->{"away"}) {
				prettyprint($state, "buddy_away", { sn => $sn } );
			} else {
				prettyprint($state, "buddy_notaway", { sn => $sn } );
			}
		}
		if ($b->{"idle"} xor $data->{"idle"}) {
			if ($data->{"idle"}) {
				prettyprint($state, "buddy_idle", { sn => $sn, idle => $data->{"idle"} } );
			} else {
				prettyprint($state, "buddy_noidle", { sn => $sn } );
			}
		}
		#my $foo = "$sn / i(" . $b->{"idle"} . ", " . $data->{"idle"} .")";
		#$foo .= " | a(" . $b->{"away"} . ", " . $data->{"away"} . ")";
		#prettyprint($state, "buddy_in", { sn => $foo } );
	}
	$state->{"buddylist"}->{$sn} = deep_copy($data);

}

sub event_buddy_info {
	my ($aim, $sn, $data) = @_;
	foreach (@{$state->{"hooks"}->{"buddy_info"}}) {
		if ($sn eq $_->{sn}) {
			&{$_->{sub}}($sn);
			return;
		}
	}

	if ($data->{"profile"}) {
		out("Buddy info for $sn");
		out("------------------");
		if (1) { # If they have w3m...
			my $prof = $data->{"profile"};
			out(`echo "$prof" | lynx -dump -stdin | grep -v '^\$'`);
		}
	}
   if ($data->{"awaymsg"}) {
		my $away = $data->{"awaymsg"};
		out("Away message for $sn:");
		out(`echo "$away" | lynx -dump -stdin | grep -v '^\$'`); 
	}

}

sub event_buddy_out {
	my ($aim, $sn, $group) = @_;
	prettyprint($state, "buddy_offline", { sn => $sn, group => $group } );
}

sub event_buddylist_error {
	my ($aim, $error, $what) = @_;
	error("An error occurred while updating your buddylist.");
	error("($error) $what");
}

sub event_buddylist_ok {
	my ($aim) = @_;
	out("Buddy list updated :)");
}

sub event_chat_buddy_in {
	my ($aim, $sn, $chat, $data) = @_;
	prettyprint($state, "chat_buddy_in", { sn => $sn, chat => $chat } );
}

sub event_chat_buddy_out {
	my ($aim, $sn, $chat) = @_;
	prettyprint($state, "chat_buddy_out", { sn => $sn, chat => $chat } );
}

sub event_chat_closed {
	my ($aim, $chat, $error) = @_;
	prettyprint($state, "chat_closed", { chat => $chat, error => $error } );
}

sub event_chat_im_in {
	my ($aim, $from, $chat, $msg) = @_;
	prettyprint($state, "chat_im_in", { chat => $chat, sn => $from, msg => $msg } );
}

sub event_connection_changed {
	my ($aim, $conn, $status) = @_;
}

sub event_error {
	my ($aim, $conn, $err, $desc, $fatal) = @_;
	error("$desc");
	if ($fatal) {
		error("This error was fatal and you have been disconnected. :(") ;
	}
}

sub event_evil {
	my ($aim, $newevil, $from) = @_; 
	prettyprint($state, "evil_user", { sn => $from, warn => $newevil } ) if (defined($from));
	prettyprint($state, "evil_anon", { warn => $newevil } ) unless (defined($from));
}

sub event_im_in {
	my ($aim, $from, $msg, $away) = @_;
	$state->{"last_from"} = $from;

	if (($state->{"logging"}->{"who_log"}->{$from} == 1) || ($state->{"config"}->{"logging"} eq "all")) {
		prettylog($state, "im_msg", { sn => $from, msg => $msg } ) unless ($away);
		prettylog($state,"im_awaymsg", { sn => $from, msg => $msg } ) if ($away);
	}
	
	prettyprint($state, "im_msg", { sn => $from, msg => $msg } ) unless ($away);
	prettyprint($state,"im_awaymsg", { sn => $from, msg => $msg } ) if ($away);
}

sub event_im_ok {
	my ($aim, $to, $reqid) = @_;
}

sub event_rate_alert {
	my ($aim, $level, $clear, $window, $worrisome) = @_;

	if ($level == $aim->RATE_CLEAR) {
	} elsif ($level == $aim->RATE_ALERT) {
		prettyprint($state, "error_rate_alert");
	} elsif ($level == $aim->RATE_LIMIT) {
		prettyprint($state, "error_rate_limit");
	} elsif ($level == $aim->RATE_DISCONNECT) {
		prettyprint($state, "error_rate_disco");
	}
}

sub event_signon_done {
	my ($aim) = @_;
	$state->{"signon"} = 0;
}

1;
