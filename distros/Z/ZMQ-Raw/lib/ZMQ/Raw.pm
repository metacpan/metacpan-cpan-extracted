package ZMQ::Raw;
$ZMQ::Raw::VERSION = '0.38';
use strict;
use warnings;
use Carp;

require XSLoader;
XSLoader::load ('ZMQ::Raw', $ZMQ::Raw::VERSION);

use ZMQ::Raw::Context;
use ZMQ::Raw::Curve;
use ZMQ::Raw::Error;
use ZMQ::Raw::Loop;
use ZMQ::Raw::Message;
use ZMQ::Raw::Poller;
use ZMQ::Raw::Proxy;
use ZMQ::Raw::Socket;
use ZMQ::Raw::Timer;
use ZMQ::Raw::Z85;

sub AUTOLOAD
{
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&ZMQ::Raw::_constant not defined" if $constname eq '_constant';
    my ($error, $val) = _constant ($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

=for HTML
<a href="https://dev.azure.com/jacquesgermishuys/p5-ZMQ-Raw/_build<Paste>">
	<img src="https://dev.azure.com/jacquesgermishuys/p5-ZMQ-Raw/_apis/build/status/jacquesg.p5-ZMQ-Raw?branchName=master" alt="Build Status: Azure" align="right" />
</a>
<a href="https://ci.appveyor.com/project/jacquesg/p5-zmq-raw">
	<img src="https://ci.appveyor.com/api/projects/status/ye43ehtq4tabkp32/branch/master?svg=true" alt="Build Status: AppVeyor" align="right" />
</a>
<a href="https://coveralls.io/github/jacquesg/p5-ZMQ-Raw">
	<img src="https://coveralls.io/repos/github/jacquesg/p5-ZMQ-Raw/badge.svg?branch=master" alt="Coverage Status" align="right"/>
</a>
=cut

=head1 NAME

ZMQ::Raw - Perl bindings to the ZeroMQ library

=head1 VERSION

version 0.38

=head1 SYNOPSIS

	use ZMQ::Raw;

	my $ctx = ZMQ::Raw::Context->new;

	my $responder = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REP);
	$responder->bind ('tcp://*:5555');

	my $requestor = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REQ);
	$requestor->connect ('tcp://localhost:5555');

	# prints: Request 'hello'
	$requestor->send ('hello');
	print "Request '", $responder->recv(), "'\n";

	# prints: Response 'world'
	$responder->send ('world');
	print "Response '", $requestor->recv(), "'\n";

=head1 METHODS

=head2 has( $feature )

Check if C<$feature> is available.

=head1 CONSTANTS

=head2 ZMQ_PAIR

=head2 ZMQ_PUB

=head2 ZMQ_SUB

=head2 ZMQ_REQ

=head2 ZMQ_REP

=head2 ZMQ_DEALER

=head2 ZMQ_ROUTER

=head2 ZMQ_PULL

=head2 ZMQ_PUSH

=head2 ZMQ_XPUB

=head2 ZMQ_XSUB

=head2 ZMQ_STREAM

=head2 ZMQ_SERVER

=head2 ZMQ_CLIENT

=head2 ZMQ_RADIO

=head2 ZMQ_DISH

=head2 ZMQ_GATHER

=head2 ZMQ_SCATTER

=head2 ZMQ_DGRAM

=head2 ZMQ_DONTWAIT

=head2 ZMQ_SNDMORE

=head2 ZMQ_POLLIN

=head2 ZMQ_POLLOUT

=head2 ZMQ_POLLERR

=head2 ZMQ_POLLPRI

=head2 ZMQ_IO_THREADS

=head2 ZMQ_MAX_SOCKETS

=head2 ZMQ_SOCKET_LIMIT

=head2 ZMQ_THREAD_PRIORITY

=head2 ZMQ_THREAD_SCHED_POLICY

=head2 ZMQ_MAX_MSGSZ

=head2 ZMQ_MSG_T_SIZE

=head2 ZMQ_THREAD_AFFINITY

=head2 ZMQ_THREAD_NAME_PREFIX

=head2 ZMQ_EVENT_CONNECTED

=head2 ZMQ_EVENT_CONNECT_DELAYED

=head2 ZMQ_EVENT_CONNECT_RETRIED

=head2 ZMQ_EVENT_LISTENING

=head2 ZMQ_EVENT_BIND_FAILED

=head2 ZMQ_EVENT_ACCEPTED

=head2 ZMQ_EVENT_ACCEPT_FAILED

=head2 ZMQ_EVENT_CLOSED

=head2 ZMQ_EVENT_CLOSE_FAILED

=head2 ZMQ_EVENT_DISCONNECTED

=head2 ZMQ_EVENT_MONITOR_STOPPED

=head2 ZMQ_EVENT_ALL

=head2 ZMQ_EVENT_HANDSHAKE_FAILED_NO_DETAIL

=head2 ZMQ_EVENT_HANDSHAKE_SUCCEEDED

=head2 ZMQ_EVENT_HANDSHAKE_FAILED_PROTOCOL

=head2 ZMQ_EVENT_HANDSHAKE_FAILED_AUTH

=head2 FEATURE_IPC

=head2 FEATURE_PGM

=head2 FEATURE_TIPC

=head2 FEATURE_NORM

=head2 FEATURE_CURVE

=head2 FEATURE_GSSAPI

=head2 FEATURE_DRAFT

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw
