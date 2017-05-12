package WebService::Uptrack;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Readonly;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;

require HTTP::Request;
require HTTP::Response;
require JSON::XS;
require LWP::UserAgent;

use version; our $VERSION = qv('0.0.2');

# DEFAULT VALUES
Readonly our $API_URL   => 'https://uptrack.ksplice.com/api';

# ATTRIBUTES AND PRIVATE METHODS

# debug flag
has 'debug' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

# Uptrack API URL
has 'url' => (
    is          => 'ro',
    isa         => 'Str',
    default     => $API_URL,
    required    => 1,
    trigger     => \&_url_trim,
);

sub _url_trim {
    my( $self, $url, $old_url ) = @_;

    $self->_debug( "\$url: $url", 3 );
    $url =~ s|/$||;
    $self->_debug( "\$url: $url", 3 );
    return( $url );
}

# Uptrack API credentials
has 'credentials' => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

# LWP::UserAgent
has '_ua' => (
    is      => 'ro',
    isa     => duck_type( 'UserAgent', [ qw( new request ) ] ),
    lazy_build  => 1,
    required    => 1,
);

sub _build__ua { return( LWP::UserAgent->new ) }

# JSON
has '_json' => (
    is      => 'ro',
    isa     => duck_type( 'JSON', [ qw( new decode_json ) ] ),
    lazy_build  => 1,
    required    => 1,
);

sub _build__json { return( JSON::XS->new ) }

sub _request {
    my( $self, $params ) = @_;

    $self->_debug( Data::Dumper->Dump( [$params], [qw(*params)] ), 3 );

    # parse params
    my( $type ) = $params->{type} || 'GET';
    my( $call ) = $params->{call} || undef;
    my( $args ) = $params->{args} || undef;

    # sanity check
    unless ( defined( $call ) ) {
        return;
    }

    # we need credentials
    my( $creds ) = [ 
                    'X-Uptrack-User'    => $self->credentials->{'user'},
                    'X-Uptrack-Key'     => $self->credentials->{'key'},
                   ];

    # build the URL
    my( $url ) = $self->url . $call;
    $self->_debug( "\$url: $url\n" );

    # instantiate the request
    my( $request ) = HTTP::Request->new( $type, $url, $creds, $args );

    $request->header( Accept => 'application/json' );

    # send it
    my( $response ) = $self->_ua->request( $request );

    # what did we get?
    if ( $response->is_success ) {
        my( $json ) = $response->decoded_content;

        my( $result ) = $self->_json->utf8->decode( $json );

        # we don't want JSON::XS::Booleans in the output
        if ( ref( $result ) eq 'ARRAY' ) {
            foreach my $element ( @{$result} ) {
                $element = _sanitizeActive( $element );
            }
        }
        else {
            $result = _sanitizeActive( $result );
        }

        return( $result );
    }
    else {
        # oh no, error
        return( 
               {
                status  => $response->code,
                error   => $response->as_string,
               } 
              );
    }
};

sub _sanitizeActive {
    my( $hashref ) = @_;

    if ( exists( $hashref->{active} ) ) {
        $hashref->{active} = $hashref->{active} ? 1 : 0;
    }

    return( $hashref );
}

sub _debug {
    my( $self, $message, $level ) = @_;

    defined( $level ) or $level = 1;

    if ( $self->debug >= $level ) {
        carp( $message );
    }
}

# PUBLIC METHODS

sub machines {
    my( $self ) = @_;

    my( $params ) = {
                     call   => "/1/machines",
                    };

    return( $self->_request( $params ) );
};

sub describe {
    my( $self, $uuid ) = @_;

    unless ( defined( $uuid ) ) {
        return;
    }

    my( $params ) = {
                     call   => "/1/machine/$uuid/describe",
                    };

    return( $self->_request( $params ) );
};

sub authorize {
    my( $self, $uuid, $bool ) = @_;

    unless ( defined( $uuid ) && defined( $bool ) ) {
        return;
    }

    # normalize $bool
    $bool = $bool ? 'true' : 'false';

    # encode the content
    my( $json ) = $self->_json->utf8->encode( { authorized => $bool } );

    my( $params ) = {
                     type   => "POST",
                     call   => "/1/machine/$uuid/describe",
                     args   => $json,
                    };

    return( $self->_request( $params ) );
}

# done with Moose magic
no Moose;
__PACKAGE__->meta->make_immutable;

1; # Magic true value required at end of module
__END__

=head1 NAME

WebService::Uptrack - access KSplice Uptrack web API

=head1 VERSION

This document describes WebService::Uptrack version 0.0.2

=head1 SYNOPSIS

    use WebService::Uptrack;
    
    my( $uptrack ) = WebService::Uptrack->new(
        credentials => {
                        user    => 'username',
                        key     => 'uptrack-API-key',
                       },
    );

    my( $machines ) = $uptrack->machines;

    foreach my $machine ( keys( %{$machines} ) ) {
        my( $uuid ) = $machine->{uuid};
        my( $status ) = $uptrack->describe( $uuid );

    };

=head1 DESCRIPTION

This module provides a Perl interface to the KSplice Uptrack web API.  API documentation is located here:

L<http://www.ksplice.com/uptrack/api>

You need to provide a valid Uptrack API username and key in order to use this module; get this via the Uptrack web interface.

=head1 INTERFACE 

=over

=item WebService::Uptrack->new

Instantiate a new C<WebService::Uptrack> object.  You must provide your credentials as a hashref with the following format:

    {
     user   => 'username',
     key    => 'api-key',
    }

You can pass the following additional parameters at creation time:

=over

=item url

C<url> is a string, defining the top-level API URL.  By default it's set to C<https://uptrack.ksplice.com/api>.

=item debug

C<debug> is an integer; if it's set greater than 0, C<WebService::Uptrack> will emit debug info via L<Carp>.

=item _ua

C<_ua> must be a reference to a L<LWP::UserAgent> object or something that works the same.

=item _json

C<_json> must be a reference to a L<JSON::XS> object or something that works the same.

=back

=item machines

The C<machines> API call.  Consult the upstream documentation for specifics.

=item describe

The C<describe> API call.  Consult the upstream documentation for specifics.

=item authorize

The C<authorize> API call.  Consult the upstream documentation for specifics.

=back

=head1 DEPENDENCIES

Carp, Data::Dumper, Readonly, Moose, Moose::Util::TypeConstraints, MooseX::StrictConstructor, HTTP::Request, HTTP::Response, LWP::UserAgent, JSON::XS 

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-uptrack@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 THANKS

Thanks to KSplice for making their API straightforward and easy to use, and thanks to The Harvard-MIT Data Center (L<http://www.hmdc.harvard.edu>) for employing me while I write this module.

=head1 AUTHOR

Steve Huff  C<< <shuff at cpan dot org> >>

=head1 LICENCE AND COPYRIGHT

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
