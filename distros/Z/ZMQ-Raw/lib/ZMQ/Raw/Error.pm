package ZMQ::Raw::Error;
$ZMQ::Raw::Error::VERSION = '0.03';
use strict;
use warnings;
use Carp;

use overload
	'""'       => sub { return $_[0] -> message.' at '.$_[0] -> file.' line '.$_[0] -> line },
	'0+'       => sub { return $_[0] -> code },
	'bool'     => sub { 1 },
	'fallback' => 1;

sub AUTOLOAD
{
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&ZMQ::Raw::Error::_constant not defined" if $constname eq '_constant';
    my ($error, $val) = _constant ($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

use ZMQ::Raw;

=head1 NAME

ZMQ::Raw::Error - Error class

=head1 VERSION

version 0.03

=head1 DESCRIPTION

A L<ZMQ::Raw::Error> represents an error.

=head1 METHODS

=head2 message( )

Error message.

=head2 file( )

Caller file.

=head2 line( )

Caller line.

=head2 code( )

Error code.

=head1 CONSTANTS

=head2 ENOTSUP

=head2 EPROTONOSUPPORT

=head2 ENOBUFS

=head2 ENETDOWN

=head2 EADDRINUSE

=head2 EADDRNOTAVAIL

=head2 ECONNREFUSED

=head2 EINPROGRESS

=head2 ENOTSOCK

=head2 EMSGSIZE

=head2 EAFNOSUPPORT

=head2 ENETUNREACH

=head2 ECONNABORTED

=head2 ECONNRESET

=head2 ENOTCONN

=head2 ETIMEDOUT

=head2 EHOSTUNREACH

=head2 ENETRESET

=head2 EFSM

=head2 ENOCOMPATPROTO

=head2 ETERM

=head2 EMTHREAD

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Error
