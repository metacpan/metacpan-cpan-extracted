package Net::Curl::Multi::EV;

use strict;
use warnings;
use EV;
use Net::Curl::Easy qw(CURLE_COULDNT_CONNECT);
use Net::Curl::Multi qw(CURLMSG_DONE CURL_SOCKET_TIMEOUT /^CURL_POLL_/ /^CURL_CSELECT_/ CURLMOPT_SOCKETFUNCTION CURLMOPT_TIMERFUNCTION);
use Scalar::Util qw(weaken);

our $VERSION = '0.01.6';

BEGIN {
	Net::Curl::Multi->can('CURLMOPT_TIMERFUNCTION') or
		die "Net::Curl::Multi is missing timer callback,\nrebuild Net::Curl with libcurl 7.16.0 or newer\n";
}


sub curl_ev {
	my ($multi) = @_;

	my %finish = (); # easy => finish
	my %timer  = (); # easy => sub

	# perform and call any callbacks that have finished
	my $multi_active = -1;
	my $socket_action = sub {

		my $active = $multi->socket_action(@_);
		return if $multi_active == $active;
		$multi_active = $active;

		while (my ($msg, $easy, $result) = $multi->info_read()) {
			if ($msg == CURLMSG_DONE) {
				delete $timer{$easy};
				$multi->remove_handle($easy);
				$finish{$easy}->($easy, $result);
				delete $finish{$easy};
			} else {
				die "I don't know what to do with message $msg.\n";
			}
		}
	};

	my $cb_timeout = sub { $socket_action->(CURL_SOCKET_TIMEOUT) };

	my $add_handle_timer;

	# add one handle and kickstart download
	my $add_handle = sub {
		my ($easy, $finish, $timeout) = @_;

		$finish{$easy} = $finish;

		# Calling socket_action with default arguments will trigger
		# socket callback and register IO events.
		#
		# It _must_ be called _after_ add_handle(); EV will take care
		# of that.
		#
		# We are delaying the call because in some cases socket_action
		# may finish inmediatelly (i.e. there was some error or we used
		# persistent connections and server returned data right away)
		# and it could confuse our application -- it would appear to
		# have finished before it started.

		$add_handle_timer = EV::timer 0, 0, $cb_timeout;

		$multi->add_handle($easy);

		if ($timeout) {
			$timer{$easy} = EV::timer $timeout, 0, sub {
				delete $timer{$easy};
				$multi->remove_handle($easy);
				$finish{$easy}->($easy, CURLE_COULDNT_CONNECT);
				delete $finish{$easy};
			};
		}
	};


	# socket callback: will be called by curl any time events on some
	# socket must be updated
	my %wr = (); # socket => $w
	my %ww = (); # socket => $w
	my $cb_socket = sub {
		my ($multi, $easy, $socket, $poll) = @_;

		# Right now $socket belongs to that $easy, but it can be
		# shared with another easy handle if server supports persistent
		# connections.
		# This is why we register socket events inside multi object
		# and not $easy.

		# register read event
		if ($poll == CURL_POLL_IN or $poll == CURL_POLL_INOUT) {
			$wr{$socket} ||= EV::io $socket, EV::READ, sub { $socket_action->($socket, CURL_CSELECT_IN) };
		} else {
			delete $wr{$socket};
		}

		# register write event
		if ($poll == CURL_POLL_OUT or $poll == CURL_POLL_INOUT) {
			$ww{$socket} ||= EV::io $socket, EV::WRITE, sub { $socket_action->($socket, CURL_CSELECT_OUT) };
		} else {
			delete $ww{$socket};
		}

		return 1;
	};


	# timer callback: It triggers timeout update. Timeout value tells
	# us how soon socket_action must be called if there were no actions
	# on sockets. This will allow curl to trigger timeout events.
	my $timer;
	my $cb_timer = sub {
		my ($multi, $timeout_ms) = @_;

		if ($timeout_ms < 0) {
			# Negative timeout means there is no timeout at all.
			# Normally happens if there are no handles anymore.
			#
			# However, curl_multi_timeout(3) says:
			#
			# Note: if libcurl returns a -1 timeout here, it just means
			# that libcurl currently has no stored timeout value. You
			# must not wait too long (more than a few seconds perhaps)
			# before you call curl_multi_perform() again.

			$timer = EV::timer 10, 10, $cb_timeout;
		} else {
			# This will trigger timeouts if there are any.
			my $t = $timeout_ms / 1000;
			$timer = EV::timer $t, $t, $cb_timeout;
		}

		return 1;
	};

	$multi->setopt(CURLMOPT_SOCKETFUNCTION, $cb_socket);
	$multi->setopt(CURLMOPT_TIMERFUNCTION,  $cb_timer);

	weaken $multi;

	return $add_handle;
}


1;

__END__

=head1 NAME

Net::Curl::Multi::EV - Using Net::Curl::Multi with EV.

=head1 SYNOPSIS

 use EV;
 use Net::Curl::Multi;
 use Net::Curl::Easy qw(/^CURLOPT_/);
 use Net::Curl::Multi::EV;
 
 my $multi   = Net::Curl::Multi->new();
 my $curl_ev = Net::Curl::Multi::EV::curl_ev($multi);

 my $easy = Net::Curl::Easy->new();
 
 $easy->setopt(CURLOPT_URL, $url);
 # ...
 
 my $finish = sub {
 	my ($easy, $result) = @_;
 	# ... $resul is Net::Curl::Easy::Code
	# ...
 	EV::break();
 };
 
 my $timeout =  4 * 60
 $curl_ev->($easy, $finish, $timeout);
 
 EV::run();

=head1 DESCRIPTION

Using Net::Curl::Multi with EV.

The module consists of the only curl_ev method, that receives the Net::Curl::Multi object and returns closures-function aimed in Net::Curl::Easy objects registration. When registering an object please define also the callback function and timeout in seconds (optional). The callback function is called when the work with Net::Curl::Easy is finished and accepts two arguments Net::Curl::Easy and Net::Curl::Easy::Code.

See example.pl file.

=head1 AUTHOR

Nick Kostyria

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Nick Kostyria

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<EV>
L<Net::Curl>
L<http://search.cpan.org/~syp/Net-Curl/lib/Net/Curl/examples.pod#Multi::Event>

=cut
