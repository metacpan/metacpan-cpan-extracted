
=head1 NAME

WebService::TicketAuth - Ticket-based authentication module for SOAP services

=head1 SYNOPSIS

    @WebService::MyService::ISA = qw(WebService::TicketAuth);

=head1 DESCRIPTION

B<WebService::TicketAuth> is an authentication system for SOAP-based web
services, that provides a signature token (like a cookie) to the client
that it can use for further interactions with the server.  This means
that the user can login and establish their credentials for their
session, then use various tools without having to provide a password for
each operation.  Sessions can be timed out, to mitigate against a ticket 
being used inappropriately.

This is similar in philosophy to authenticated web sessions where the
user logs in and gains a cookie that it can use for further
interactions.  For example, see Apache::AuthTicket.  However, such
systems require a web server such as Apache to handle the
authentication.  This module provides a mechanism that can be used 
outside of a web server.  In particular, it is designed for use with
a SOAP daemon architecture.

This module was originally developed by Paul Kulchenko in 2001.  See
guide.soaplite.com for more info.

=head1 FUNCTIONS

=cut

package WebService::TicketAuth;

# we will need to manage Header information to get a ticket
@WebService::TicketAuth::ISA = qw(SOAP::Server::Parameters);

use strict;
use Digest::MD5 qw(md5);

use vars qw($VERSION %FIELDS);
our $VERSION = '1.05';

use fields qw(
              _error_msg
              _debug
              );

my $calculateAuthInfo = sub {
    return md5(join '', 'WebService::TicketAuth', $VERSION, @_);
};

my $makeAuthInfo = sub {
    my $username = shift;
    my $duration = shift || 20*60;

    if (! $username) {
        return undef;
    }

    # Length of time signature will be valid
    my $time = time() + $duration;

    # Create the signature
    my $signature = $calculateAuthInfo->($username, $time);

    return +{time => $time, username => $username, signature => $signature};
};

my $checkAuthInfo = sub {
    my $authInfo = shift;
    if (! $authInfo) {
        return undef;
    }

    my $signature = $calculateAuthInfo->(@{$authInfo}{qw(username time)});

    if ($signature ne $authInfo->{signature}) {
        return undef;
    } elsif (time() > $authInfo->{time}) {
        return undef;
    } else {
        return $authInfo->{username};
    }
};


=head2 new()

Creates a new instance of TicketAuth.  Establishes several private member
functions for authentication, to calculate, make, and check the authInfo.

=cut

sub new {
    my WebService::TicketAuth $self = shift;
    if (! ref $self) {
        $self = fields::new($self);
    }
    return $self;
}

# Internal routine for setting the error message
sub _set_error {
    my $self = shift;
    $self->{'_error_msg'} = shift;
}

=head2 get_error()

Returns the most recent error message.  If any of this module's routines
return undef, this routine can be called to retrieve a message about
what happened.  If several errors have occurred, this will only return
the most recently encountered one.

=cut

sub get_error {
    my $self = shift;
    return $self->{'_error_msg'};
}

=head2 ticket_duration($username)

This routine defines how long a ticket should last.  Override it to
customize the ticket lengths.  The username is provided when requesting
this information, to permit applications to vary ticket length based
on the user's access level, if desired.  If $username is undef, then a
generic duration should be returned.  

By default, the ticket duration is defined to be 20 minutes (or 20*60
seconds).

=cut

sub ticket_duration {
    my $self = shift;
    my $username = shift;
    return 20*60;
}


=head2 get_username($header)

Retrieves the username from the auth section of the SOAP header

=cut

sub get_username {
    my $self = shift;
    my $header = shift || return undef;

    return $checkAuthInfo->($header->valueof('//authInfo'));
}

=head2 is_valid($username, $password)

Routine to determine if the given user credentials are valid.  Returns 1
to indicate if the credentials are accepted, or undef if not.  Error
messages can be retrieved from the get_error() routine.

Override this member function to implement your own authentication system.
This base class function always returns false.

=cut

sub is_valid {
    my $self = shift;
    my ($username, $password) = @_;

    $self->_set_error("Error:  Base class is_valid() called.  ".
                      "Validation must be performed by a derived class.\n");

    return undef;
}

=head2 login()

This routine is called by users to establish their credentials.  It
returns an AuthInfo ticket on success, or undef if the login failed
for any reason.  The error message can be retrieved from get_error().

It checks credentials by calling the is_valid() routine, which should be
overridden to hook in your own authentication system. 

=cut

sub login {
    my $self = shift;

    pop;  # Last parameter is the SOAP envelope - we ignore it
    my ($username, $password) = @_;

    # Check credentials
    if (! $self->is_valid($username, $password)) {
        return undef;
    } else {
        return $makeAuthInfo->($username, $self->ticket_duration());
    }
}


1;
__END__

=head1 AUTHORS

Paul Kulchenko, paulclinger at yahoo dot com.  Original module created
as part of SOAP::Lite user's guide.  See http://guide.soaplite.com.

Bryce Harrington, bryce at bryceharrington dot org.  OO-ified,
documented, etc.

=head1 COPYRIGHT

Copyright (C) 2001 Paul Kulchenko.  All rights reserved.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<SOAP::Lite>, L<Apache::AuthTicket>

=cut
