package HTTP::Tiny;

use 5.008;

use strict;
use warnings;

use Carp;
use Storable ();

our $VERSION = '0.006';

use constant HASH_REF	=> ref {};

BEGIN {
    local $@ = undef;

    eval {
	require HTTP::Status;
	*_status_message = \&HTTP::Status::status_message;
	1;
    } or *_status_message = sub {
	my ( $status ) = @_;
	return _is_success( $status ) ? 'OK' : 'Failed';
    };
}

sub new {
    my ( $class, %arg ) = @_;
    defined $arg{fn}
	or $arg{fn} = 't/data/_http/status';
    if ( defined $arg{agent} ) {
	$arg{agent} =~ m/ \s \z /smx
	    and $arg{agent} .= $class->_default_agent();
    } else {
	$arg{agent} = $class->_default_agent();
    }
    return bless \%arg, ref $class || $class;
}

sub agent {
    my ( $invocant ) = @_;
    ref $invocant
	or return $invocant->_default_agent();
    return $invocant->{agent};
}

sub _default_agent {
    my ( $self ) = @_;
    ( my $agent = ref $self || $self ) =~ s/ :: /-/smxg;
    return join '/', "Mock $agent", $self->VERSION();
}

sub head {
    my ( $self, $url ) = @_;
    return $self->request( HEAD => $url );
}

sub request {
    my ( $self, undef, $url ) = @_;
    $self->{status} ||= Storable::retrieve( $self->{fn} );
    my $resp = $self->{status}{$url};
    HASH_REF eq ref $resp
	or $resp = {
	status	=> $resp || 404,
    };
    $resp->{success} = _is_success( $resp->{status} );
    defined $resp->{reason}
	or $resp->{reason} = _status_message( $resp->{status} );
    defined $resp->{url}
	or $resp->{url} = $url;
    defined $resp->{content}
	or $resp->{content} = '';
    $resp->{headers} ||= {};
    return $resp;
}

sub _is_success {
    my ( $status ) = @_;
    return $status >= 200 && $status < 300;
}

1;

__END__

=head1 NAME

HTTP::Tiny - Mock HTTP::Tiny class

=head1 SYNOPSIS

 use lib qw{ inc/Mock };

 use HTTP::Tiny;

 ...

=head1 DESCRIPTION

This Perl class mocks whatever portion of the L<HTTP::Tiny|HTTP::Tiny>
interface is needed by
L<Test::Pod::LinkCheck::Lite|Test::Pod::LinkCheck::Lite>. It is private
to that distribution, and may change or be revoked without notice.
Documentation is for the benefit of the author.

It works by reading a L<Storable|Storable> file which contains a hash
mapping URLs to desired status codes. When a request is made, the URL is
looked up in the hash, and a respose with the requested status is
returned. If the URL is not found, the status is C<404>.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $ua = HTTP::Tiny->new();

This static method instantiates the object. Optional arguments may be
passed as name/value pairs. The only supported argument is

=over

=item agent

This argument specifies the user agent string. If it ends in a space the
default user agent string is appended.

=item fn

This argument specifies the file to read for the desired statuses. The
default is F<t/data/_http/status>. This argument is B<not> recognized by
the real L<HTTP::Tiny|HTTP::Tiny>.

=back

=head2 agent

 my $user_agent_string = ua->agent();

This method retrieves (but does not set) the user agent string.

=head2 head

 my $resp = $ua->head( $url );

This method simulates a C<HEAD> request. It simply delegates to the
L<request()|/request> method.

=head2 request

 my $resp = $ua->request( $method => $url );

This method simulates executing the given method against the given url.
The C<$method> is actually ignored. The status of the request is derived
by reading the status file (see argument C<fn> to L<new()|/new>) and
looking up the given URL. If it is found, the specified status is used.
Otherwise the status is 404.

All standard fields in the response hash are populated. However, all
have static values except for the following:

=over

=item reason

If L<HTTP::Status|HTTP::Status> can be loaded, this will be the reason
message appropriate to the code. Otherwise it will be C<'OK'> for a
success code or C<'Failed'> otherwise.

=item status

The status of the request.

=item success

True if the status is 2xx; false otherwise.

=item url

The requested URL.

=back

=head1 SEE ALSO

L<HTTP::Tiny|HTTP::Tiny> (the real one).

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://github.com/trwyant/perl-Test-Pod-LinkCheck-Lite/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
