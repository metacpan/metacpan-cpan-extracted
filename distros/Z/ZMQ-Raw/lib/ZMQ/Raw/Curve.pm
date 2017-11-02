package ZMQ::Raw::Curve;
$ZMQ::Raw::Curve::VERSION = '0.12';
use strict;
use warnings;
use ZMQ::Raw;

=head1 NAME

ZMQ::Raw::Curve - ZeroMQ CURVE methods

=head1 VERSION

version 0.12

=head1 DESCRIPTION

ZeroMQ CURVE methods.

=head1 SYNOPSIS

	use ZMQ::Raw;

	# client
	my ($private, $public) = ZMQ::Raw::Curve->keypair();

	my $req = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REQ);
	$req->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_SECRETKEY, $private);
	$req->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_PUBLICKEY, $public);
	$req->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_SERVERKEY, $server_public);

	# server
	my $private = ZMQ::Raw::Curve->keypair();

	my $rep = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REP);
	$rep->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_SECRETKEY, $private);
	$rep->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_SERVER, 1);
	$rep->bind ('tcp://*:5555');

=head1 METHODS

=head2 keypair( )

Create a new, generated random keypair consisting of a private and public key.
Returns the private and public key in list context and only the private key
in scalar context.

=head2 public( $private )

Derive the public key from a private key.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Curve
