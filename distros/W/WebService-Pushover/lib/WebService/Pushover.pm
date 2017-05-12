package WebService::Pushover;
use strict;

use Moo;

binmode STDOUT, ":encoding(UTF-8)";

use Carp;
use DateTime;
use DateTime::Format::Strptime;
use File::Spec;
use WebService::Simple;
use WebService::Simple::Parser::JSON;
use Params::Validate qw( :all );
use Readonly;
use URI;

use version; our $VERSION = qv('1.0.0');

# Module implementation here

# constants
Readonly my $REGEX_FORMAT => '^(?:json|xml)$';
Readonly my $REGEX_TOKEN => '^[A-Za-z0-9]{30}$';
Readonly my $REGEX_DEVICE => '^[A-Za-z0-9_-]{0,25}$';
Readonly my $REGEX_NUMERIC => '^\d+$';
Readonly my $REGEX_SOUNDS => '^(?:pushover|bike|bugle|cashregister|classical|cosmic|falling|gamelan|incoming|intermission|magic|mechanical|pianobar|siren|spacealarm|tugboat|alien|climb|persistent|echo|updown|none)$';

Readonly my $SIZE_TITLE => 50;
Readonly my $SIZE_MESSAGE => 512;
Readonly my $SIZE_URL => 200;
Readonly my $SIZE_RETRY => 30;
Readonly my $SIZE_EXPIRE => 86400;

has debug => (
    is => 'ro',
    default => sub { 0 },
    coerce => sub { $_[0] ? 1 : 0 },
);

# NB: We can't call this 'user', as there's already a method called that.
has user_token => (
    is       => 'ro',
    required => 0,
    isa      => sub { $_[0] =~ /$REGEX_TOKEN/ or die "Invalid user token: $_[0]" },
);

has api_token => (
    is       => 'ro',
    required => 0,
    isa      => sub { $_[0] =~ /$REGEX_TOKEN/ or die "Invalid api token: $_[0]" },
);

has base_url => (
    default => "https://api.pushover.net",
    is      => 'ro',
);

has _urls => (
    is => 'ro',
    default => sub {
        return {
            messages => '/1/messages.json',
            users    => '/1/users/validate.json',
            receipts => '/1/receipts/$receipt$.json',
            sounds   => '/1/sounds.json',
        };
    },
);

has api => (
    is => 'lazy',
);

sub _build_api {
    my ($self) = @_;
    return WebService::Simple->new(
        response_parser => WebService::Simple::Parser::JSON->new,
        base_url        => $self->base_url,
        debug           => $self->debug,
    );
}

has specs => (
    is => 'lazy',
);

sub _build_specs {
    my $self = shift();
    my $SPECS = {
        token => {
            type  => SCALAR,
            regex => qr/$REGEX_TOKEN/,
        },
        user => {
            type  => SCALAR,
            regex => qr/$REGEX_TOKEN/,
        },
        device => {
            optional => 1,
            type     => SCALAR,
            regex    => qr/$REGEX_DEVICE/,
        },
        receipt => {
            type  => SCALAR,
            regex => qr/$REGEX_TOKEN/, # yes, receipts are formatted like tokens
        },
        callback => {
            optional => 1,
            type  => SCALAR,
            callbacks => {
                "valid URL" => sub {
                    my $url = shift;
                    my $uri = URI->new( $url );
                    defined( $uri->as_string() );
                },
            },
        },
        title => {
            optional  => 1,
            type      => SCALAR,
            callbacks => {
                "$SIZE_TITLE characters or fewer" => sub { length( shift() ) <= $SIZE_TITLE },
            },
        },
        message => {
            type      => SCALAR,
            callbacks => {
                "$SIZE_MESSAGE characters or fewer" => sub { length( shift() ) <= $SIZE_MESSAGE },
            },
        },
        timestamp => {
            optional  => 1,
            type      => SCALAR,
            callbacks => {
                "Unix epoch timestamp" => sub {
                    my $timestamp = shift;
                    my $strp = DateTime::Format::Strptime->new(
                        pattern   => '%s',
                        time_zone => "floating",
                        on_error  => "undef",
                    );
                    defined( $strp->parse_datetime( $timestamp ) );
                },
            },
        },
        priority => {
            optional  => 1,
            type      => SCALAR,
            callbacks => {
                "valid or undefined" => sub {
                    my $priority = shift;
                    my( %priorities ) = (
                        0  => 'valid',
                        1  => 'valid',
                        -1 => 'valid',
                        2  => 'valid',
                    );
                    ( ! defined( $priority ) )
                        or exists $priorities{$priority};
                },
            },
        },
        url => {
            optional  => 1,
            type      => SCALAR,
            callbacks => {
                "valid URL" => sub {
                    my $url = shift;
                    my $uri = URI->new( $url );
                    defined( $uri->as_string() );
                },
            },
        },
        url_title => {
            optional  => 1,
            type      => SCALAR,
            callbacks => {
                "$SIZE_TITLE characters or fewer" => sub { length( shift() ) <= $SIZE_TITLE },
            },
        },
        sound => {
            optional => 1,
            type     => SCALAR,
            regex    => qr/$REGEX_SOUNDS/,
        },
        retry => {
            optional => 1,
            type     => SCALAR,
            callbacks => {
                "numeric" => sub { shift() =~ /$REGEX_NUMERIC/ },
                "$SIZE_RETRY seconds or more" => sub { shift() >= $SIZE_RETRY },
            }
        },
        expire => {
            optional => 1,
            type     => SCALAR,
            callbacks => {
                "numeric" => sub { shift() =~ /$REGEX_NUMERIC/ },
                "$SIZE_EXPIRE seconds or fewer" => sub { shift() <= $SIZE_EXPIRE },
            }
        },
    };

    my %messages_spec = (
        token     => $SPECS->{token},
        user      => $SPECS->{user},
        device    => $SPECS->{device},
        title     => $SPECS->{title},
        message   => $SPECS->{message},
        timestamp => $SPECS->{timestamp},
        priority  => $SPECS->{priority},
        callback  => $SPECS->{callback},
        sound     => $SPECS->{sound},
        retry     => $SPECS->{retry},
        expire    => $SPECS->{expire},
        url       => $SPECS->{url},
        url_title => $SPECS->{url_title},
    );

    my %users_spec = (
        token  => $SPECS->{token},
        user   => $SPECS->{user},
        device => $SPECS->{device},
    );

    my %receipts_spec = (
        token   => $SPECS->{token},
        receipt => $SPECS->{receipt},
    );

    my %sounds_spec = (
        token  => $SPECS->{token},
    );

    return {
        messages => \%messages_spec,
        users    => \%users_spec,
        receipts => \%receipts_spec,
        sounds   => \%sounds_spec,
    };
}

sub _apicall {
    my ($self, $method, $call, @rest) = @_;

    my $spec = $self->specs->{$call}
        or croak( "'$call' is not a supported API call." );
    my $url    = $self->_urls->{$call}
         or croak( "'$call' is not a supported API call." );
    my $params = validate( @rest, $spec );

    while ($url =~ /\$(\S+?)\$/) {
        my $arg = $1;
        my $val = delete($params->{$arg}) || "";
        $url =~ s/\$$arg\$/$val/g;
    }

    return $self->api->$method($url, $params)->parse_response;
}

sub message {
    my ($self, %opts) = @_;

    return $self->_apicall(post => 'messages',
        user  => $self->user_token,
        token => $self->api_token,
        %opts,
    );
}

sub user {
    my ($self, %opts) = @_;

    return $self->_apicall(post => 'users',
        user  => $self->user_token,
        token => $self->api_token,
        %opts,
    );
}

sub receipt {
    my ($self, %opts) = @_;

    return $self->_apicall(get => 'receipts',
        token => $self->api_token,
        %opts,
    );
}

sub sounds {
    my ($self, %opts) = @_;

    return $self->_apicall(get => 'sounds',
        token => $self->api_token,
        %opts,
    );
}

# ok, add some backwards compatibility
before 'push' => sub {
    carp( "The 'push' method is deprecated in WebService::Pushover v0.1.0, and will be removed in a future release.  Please use the 'message' method instead." );
};

sub push {
    my $self = shift;
    $self->message( @_ );
}

before 'tokens' => sub {
    carp( "The 'tokens' method is deprecated in WebService::Pushover v0.1.0, and will be removed in a future release.  Please use the 'user' method instead." );
};

sub tokens {
    my $self = shift;
    $self->user( @_ );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

WebService::Pushover - interface to Pushover API

=head1 VERSION

This document describes WebService::Pushover version 1.0.0.

=head1 SYNOPSIS

    use WebService::Pushover;

    my $push = WebService::Pushover->new(
        user_token => 'PUSHOVER USER TOKEN',
        api_token  => 'PUSHOVER API TOKEN',
    ) or die( "Unable to instantiate WebService::Pushover.\n" );

    my %params = (
        message  => 'test test test',
        priority => 0,
    );

    my $status = $push->message( %params );

=head1 DESCRIPTION

This module provides a Perl wrapper around the Pushover
( L<http://pushover.net> ) RESTful API.  You'll need to register with
Pushover to obtain an API token for yourself and for your application
before you'll be able to do anything with this module.

=head1 INTERFACE

=over 4

=item new(I<%params>)

Creates an object that allows for interaction with Pushover. The following
are valid arguments; all are optional:

=over 4

=item base_url B<OPTIONAL>

Sets the base URL for the API to connect to. Defaults to L<http://api.pushover.net>

=item user_token B<OPTIONAL>

The Pushover user token, obtained by registering at L<http://pushover.net>.
If specified, will be used as a default in any call that requires a user token.

=item api_token B<OPTIONAL>

The Pushover application token, obtained by registering at L<http://pushover.net/apps>.
If specified, will be used as a default in any call that requires an API token.

=item debug B<OPTIONAL>

Set this to a true value in order to enable tracing of API call operations.

=back

=item debug()

I<debug()> returns 1 if debugging is enabled, and 0 otherwise.

=item message(I<%params>)

I<message()> sends a message to Pushover and returns a scalar reference
representation of the message status.  The following are valid parameters:

=over 4

=item token B<OPTIONAL>

The Pushover application token.
If not specified, the C<api_token> specified in C<new> will be used.

=item user B<OPTIONAL>

The Pushover user token.
If not specified, the C<user_token> specified in C<new> will be used.

=item device B<OPTIONAL>

The Pushover device name; if not supplied, the user will be validated if at
least one device is registered to that user.

=item title B<OPTIONAL>

A string that will appear as the title of the message; if not supplied, the
name of the application registered to the application token will appear.

=item message B<REQUIRED>

A string that will appear as the body of the message.

=item timestamp B<OPTIONAL>

The desired message timestamp, in Unix epoch seconds.

=item priority B<OPTIONAL>

Set this value to "2" to mark the message as emergency priority, "1" to mark
the message as high priority, set it to "-1" to mark the message as low
priority, or set it to "0" or leave it unset for standard priority.

=item retry B<OPTIONAL>

You must pass this parameter when sending messages at emergency priority.  Set
this value to the number of seconds before Pushover tries again to obtain
confirmation of message receipt.

=item expire B<OPTIONAL>

You must pass this parameter when sending messages at emergency priority.  Set
this value to the number of seconds before Pushover stops trying to obtain
confirmation of message receipt.

=item url B<OPTIONAL>

A string that will be attached to the message as a supplementary URL.

=item url_title B<OPTIONAL>

A string that will be displayed as the title of any supplementary URL.

=item sound B<OPTIONAL>

Select a sound to be associated with this notification.  Check the Pushover API
documentation for valid values.

=back

=item user(I<%params>)

I<user()> sends an application token and a user token to Pushover and
returns a scalar reference representation of the validity of those tokens.  The
following are valid parameters:

=over 4

=item token B<OPTIONAL>

The Pushover application token.
If not specified, the C<api_token> specified in C<new> will be used.

=item user B<OPTIONAL>

The Pushover user token.
If not specified, the C<user_token> specified in C<new> will be used.

=item device B<OPTIONAL>

The Pushover device name; if not supplied, the message will go to all devices
registered to the user token.

=back

=item receipt(I<%params>)

I<receipt()> sends an application token and a receipt token to Pushover and
returns a scalar reference representation of the confirmation status of the
notification associated with the receipt.  The following are valid parameters:

=over 4

=item token B<OPTIONAL>

The Pushover application token.
If not specified, the C<api_token> specified in C<new> will be used.

=item receipt B<REQUIRED>

The Pushover receipt token, obtained by parsing the output returned after
sending a message with emergency priority.

=back

=item sounds(I<%params>)

I<sounds()> sends an application token to Pushover and returns a hash reference
listing the available sounds (suitable for passing to the I<sound> parameter of
the I<message()>.  The following are valid parameters:

=over 4

=item token B<OPTIONAL>

The Pushover application token.
If not specified, the C<api_token> specified in C<new> will be used.

=back

=back

=head2 DEPRECATED METHODS

The following methods are depreated, and will be removed in a future
release. They remain for now to provide backwards compatibility.

=over

=item push(I<%params>)

I<push()> is a B<DEPRECATED> alias for I<message()>.

=item tokens(I<%params>)

I<tokens()> is a B<DEPRECATED> alias for I<user()>.

=back

=head1 DIAGNOSTICS

Inspect the value returned by any method, which will be a Perl data structure
parsed from the JSON or XML response returned by the Pushover API.

=head1 DEPENDENCIES

=over 4

=item L<DateTime>

=item L<DateTime::Format::Strptime>

=item L<Moo>

=item L<WebService::Simple>

=item L<WebService::Simple::Parser::JSON>

=item L<Params::Validate>

=item L<Readonly>

=item L<URI>

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at L<https://github.com/hakamadare/webservice-pushover/issues>.

=head1 AUTHOR

Steve Huff  C<< <shuff@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Steve Huff C<< <shuff@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
