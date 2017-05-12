package WebService::Etsy;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Carp;
use WebService::Etsy::Response;
use IO::File;
use WebService::Etsy::Resource;

use base qw( Class::Accessor WebService::Etsy::Methods );
__PACKAGE__->mk_accessors( qw( ua api_key base_uri last_error default_detail_level default_limit _log_fh use_sandbox ) );

our $VERSION = '0.7';

=head1 NAME

WebService::Etsy - Access the Etsy REST API.

=cut

=head1 SYNOPSIS

    my $api = WebService::Etsy->new( api_key => 'key' );

    # Call API methods as object methods
    my $resp = $api->getUsersByName( search_name => 'test' );
    die $api->last_error if ( ! defined $resp );

    # Returns a Response object which has methods
    print "Found: " . $resp->count . " users\n";
    print "Have: " . scalar @{ $resp->results } . " results\n";

    # But also behaves like an arrayref of Resource objects
    for ( @$resp ) {
        # Resources are objects, like WebService::Etsy::Resource::User
        print $_->user_name, "\n";
    }

    $resp = $api->getUserDetails( user_id => 'testuser' );
    # As a convenience, you can call Resource object methods
    # on the Response object, which will be called on the first
    # Resource object so
    print $resp->user_name, "\n";
    # is the same as
    print $resp->[ 0 ]->user_name, "\n";

=head1 DESCRIPTION

Note: this module is alpha code - a fairly functional proof of concept. In addition, this 0.7 release is a quick hack to make something that works with the v2 API since the v1 API is being taken offline. It doesn't support the "private" API, only the "public" (no OAuth) API, and then only a subset that matches roughly with what the v1 API provided. The v2 API's method names aren't backwards-compatible with the v1 API so some re-writing will be necessary.

This module accesses the Etsy API, as described at L<http://developer.etsy.com/>.

The API is RESTful, and returns JSON. This module abstracts this away to present a standard Perl object interface.

The API methods are generated from details returned by the C<getMethodsTable> API method. A pre-built package containing the methods is shipped with this distribution, but you can re-build it using the "generate_methods.pl" script that is distributed with this code:

   perl generate_methods.pl api_key > Methods.pm

C<Methods.pm> should then replace the existing C<WebService::Etsy::Methods> file in your Perl library.

Currently the data is provided just as it comes back from the Etsy API. Future development will include caching, automatic retrieval of larger data sets, cross-object references, etc.

Calls to the API methods of the C<WebService::Etsy> object will return a L<WebService::Etsy::Response> object. See that object's documentation on the methods available.

The Response object contains an arrayref of L<WebService::Etsy::Resource> objects, which implement interfaces to match the documentation at L<http://developer.etsy.com/docs/read/resources>. See the L<WebService::Etsy::Resource> page for documentation on specific methods.

=head1 METHODS

=over 4

=item C<new( %opts )>

Create a new API object. Takes a hash of options which can include C<ua>, C<api_key>, C<use_sandbox>, C<base_uri>, C<log_file>, C<default_limit>, and C<default_detail_level>, which correspond to setting the values of the relevant methods (described below).

=item C<api_key( $key )>

Get/set the API key to use for API requests.

=item C<use_sandbox( $bool )>

Boolean toggle controlling whether to access the sandbox version of the API or not.

=item C<base_uri( $uri )>

Get/set the base URI for requests. Defaults to "http://beta-api.etsy.com/v1".

=item C<ua( $agent )>

Get/set the user agent object that will be used to access the API server. The agent should be an object that implements the same interface as L<LWP::UserAgent>.

By default, it's an LWP::UserAgent with the agent string "WebService::Etsy".

=item C<default_limit( $limit )>

Get/set the default limit parameter for a request for those methods that accept a limit parameter. Takes an integer 1-50. Default is 10.

=item C<default_detail_level( $level )>

Get/set the default detail level to request for those methods that accept such a parameter. Takes one of "low", "medium", or "high". Default is "low".

=item C<last_error>

Returns the message from the last error encountered.

=item C<log_file>

Get/set the name of the log file to use.

=item C<log( $message )>

Write C<$message> to the log.

=back

=head1 API METHODS

API methods take a hash of parameters. In the event of an error, they will return undef, and the error message can be retrieved using the C<last_error()> method.

    my $resp = $api->getUserDetails( user_id => 'testuser', detail_level => 'high' );

See L<http://developer.etsy.com/docs#commands> for more details on the methods and parameters.

Any API method will also accept C<ua>, C<base_uri>, or C<api_key> arguments which will override those configured in the API object.

=cut

sub new {
    my $proto = shift;
    my $class = ref ( $proto ) || $proto;
    my $self = bless {}, $class;
    my %args = @_;

    $self->ua( $args{ ua } || LWP::UserAgent->new( agent => 'WebService::Etsy' ) );
    $self->base_uri( $args{ base_uri } || 'http://openapi.etsy.com/v2' );
    $self->api_key( $args{ api_key } );
    $self->use_sandbox( $args{ use_sandbox } );
    $self->default_detail_level( $args{ default_detail_level } );
    $self->default_limit( $args{ default_limit } );
    if ( $args{ log_file } ) {
        $self->log_file( $args{ log_file } );
    }
    return $self;
}

sub _call_method {
    my $self = shift;
    my $method_info = shift;
    my %args = @_;
    for ( qw( ua api_key base_uri ) ) {
        if ( ! exists $args{ $_ } ) {
            $args{ $_ } = $self->$_();
        }

    }
    if ( ! $args{ api_key } ) {
        croak "No API key specified";
    }
    my $uri = $method_info->{ uri };
    my @missing;
    my %params = %{ $method_info->{ params } };
    $params{ api_key } = "";
    while ( $uri =~ /{(.+?)}/g ) {
        my $param = $1;
        if ( ! exists $args{ $param } ) {
            push @missing, $param;
        } else {
           $uri =~ s/{(.+?)}/$args{ $param }/;
           delete $params{ $param };
        }
    }
    for my $field ( qw( detail_level limit ) ) {
        if ( exists $params{ $field } && ! exists $args{ $field } ) {
            my $method = "default_$field";
            $args{ $field } = $self->$method;
        }
    }
    for ( keys %params ) {
        if ( $args{ $_ } ) {
            $params{ $_ } = $args{ $_ };
        } else {
            delete $params{ $_ };
        }
    }
    if ( scalar @missing ) {
        $self->last_error( "Missing required argument" . ( ( scalar @missing > 1 ) ? "s" : "" ) . " in call to " . $method_info->{ name } . ": " . join ", ", @missing );
        return;
    }
    my $params = join "&", map{ "$_=$params{ $_ }" } keys %params;
    $uri = $args{ base_uri } . $self->_sandbox . '/' . $method_info->{visibility} . $uri . "?" . $params;
    my $resp = $args{ ua }->get( $uri );
    my $log_msg = $uri . "," . $resp->code;
    if ( ! $resp->is_success ) {
        $log_msg .= "," . $resp->content;
        $self->log( $log_msg );
        $self->last_error( "Error getting resource $uri: " . $resp->status_line );
        return;
    }
    $self->log( $log_msg );
    my $data = from_json( $resp->content );

    my $detail = ( $data->{ params } && ref $data->{ params } eq "HASH" ) ? $data->{ params }->{ detail_level } : undef;
    my $class = 'WebService::Etsy::Resource::' . $method_info->{ type };
    for ( 0 .. $#{ $data->{ results } } ) {
        my %extra = ( api => $self );
        if ( $detail ) {
            $extra{ detail_level } = $detail;
        }
        $data->{ results }->[ $_ ] = $class->new( $data->{ results }->[ $_ ], %extra );
    }
    return bless $data, "WebService::Etsy::Response";
}

sub _sandbox {
    my $self = shift;
    return ($self->use_sandbox) ? '/sandbox' : '';
}

sub log {
    my ( $self, $msg ) = @_;
    my $fh = $self->_log_fh || return;
    $fh->print( time . "," . $$ . "," . $msg . "\n" );
}

sub log_file {
    my ( $self, $file ) = @_;
    if ( $file ) {
        my $fh = IO::File->new;
        $fh->open( ">>" . $file ) or croak qq(Can't open log file $file: $!);
        $self->_log_fh( $fh );
    }
    return;
}

sub DESTROY {
    my $self = shift;
    my $fh = $self->_log_fh;
    $fh->close if $fh;
}

=head1 SEE ALSO

L<http://www.etsy.com/storque/etsy-news/tech-updates-handmade-code-etsys-beta-api-3055/>, L<http://developer.etsy.com/>, L<WebService::Etsy::Response>, L<WebService::Etsy::Resource>.

=head1 AUTHOR

Ian Malpass (ian-cpan@indecorous.com)


=head1 COPYRIGHT

Copyright 2009, Ian Malpass

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
