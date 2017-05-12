package Test::Mock::REST::Client;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Digest::SHA qw(sha256_hex);
use English;
use File::Basename;
use File::Slurp qw(slurp);
use File::Spec::Functions;
use URI;
use URI::QueryParam;

use Test::MockModule;
use Test::MockObject;
use Hook::LexWrap;

#use Smart::Comments -ENV;

our $response_directory = './t/responses/';
our $request_counter    = 0;

sub flatten_params {
    my ( $params ) = @_;

    ## flatten_params: Dumper($params)

    my $result = '';

    # FIXME rewrite with map
    foreach my $k ( sort keys %$params ) {
        next
          if $k eq 'sig' || $k eq 'format' || $k eq 'time' || $k eq 'token' || $k eq 'delete_token';
        $result .= sprintf '%s%s', $k, $params->{$k};
    }

    ## flatten_params_result: $result
    return $result;
}

sub request_signature {
    my ( $client, $method, $uri, $params, $payload ) = @_;

    ## sign_method: $method
    ## sign_uri: $uri

    #    my $signature = sprintf '%03d', $request_counter;

    #    $signature .= $method . $uri;
    #    $signature .= flatten_params( $params )  if defined $params;
    #    $signature .= flatten_params( $payload ) if defined $payload;

    $uri =~ s/\//_/g;

    ## signature_string: $signature
    my $signature = sprintf "%s_%03d_%s_%s", basename( $PROGRAM_NAME ), $request_counter, $method,
      $uri;
    ### request_signature: $signature
    $request_counter += 1;

    return $signature;
}

sub request_signature_from_uri {
    my ( $client, $method, $uri, $payload ) = @_;

    ## request_signature_from_uri: Dumper( @_ )
    ### request_uri: $uri

    my $u = URI->new( $uri );

    my $params = {};
    foreach my $k ( $u->query_param ) {
        $params->{$k} = $u->query_param( $k );
    }
    ### params: $params

    ### payload: $payload
    if ( $payload eq '' ) {
        $payload = undef;
    }
    else {
        my $up = URI->new( '?' . $payload );
        ### up: $up->as_string
        $payload = {};
        foreach my $k ( $up->query_param ) {
            $payload->{$k} = $up->query_param( $k );
        }
    }

    my $uri_path = $u->path;
    my $base_url = $client->get_base_url;
    $uri_path =~ s/$base_url\///i;

    return request_signature( $client, $method, $uri_path, $params, $payload );
} ## end sub request_signature_from_uri

sub save_response {
    my ( $request_signature, $result_code, $result ) = @_;

    return unless -d $response_directory;
    my $filename = catfile( $response_directory, $request_signature );

    croak "response file already exists $filename" if ( -f $filename );

    open( my $fh, '>', $filename ) or die 'unable to open file for writing:', $!;
    print $fh $result_code;
    print $fh $result if defined $result;
    close $fh;

    return;
}

sub load_response {
    my ( $request_signature ) = @_;

    return unless -d $response_directory;

    my $filename = catfile( $response_directory, $request_signature );
    return ( '404', '' ) unless -r $filename;

    my $content = slurp( $filename ) || q{};
    my ( $result_code, $result ) = ( '404', '' );

    if ( $content ) {
        $result_code = substr( $content, 0, 3 );
        $result = substr( $content, 3 );
    }
    return ( $result_code, $result );
}

sub setup_mock {
    my ( $client ) = @_;

    my $restclient;

    if ( $ENV{BIGDOOR_TEST_SAVE_RESPONSES} ) {
        ### Save Responses...
        wrap 'WWW::BigDoor::do_request', post => sub {
            my ( $self, $method ) = @_;

            my $result = pop( @_ );
            my $result_code = defined $result ? '200' : '404';
            $result_code = $self->get_response_code() if defined $self;

            if ( $method =~ /^GET|DELETE|PUT|POST$/i ) {
                save_response( request_signature( @_ ), $result_code, $result );
            }
        };
    }
    elsif ( !$ENV{BIGDOOR_TEST_LIVESERVER} ) {
        ### Mock REST Client ...
        $restclient = Test::MockModule->new( 'REST::Client' );
        $restclient->mock(
            request => sub {
                shift;
                my ( $result_code, $content ) =
                  load_response( request_signature_from_uri( $client, @_ ) );
                my $result = Test::MockObject->new();
                $result->mock( 'responseCode',    sub { $result_code } );
                $result->mock( 'responseContent', sub { return $content; } );
                return $result;
            }
        );
    }
    return $restclient;
} ## end sub setup_mock

sub missing_responses {
    if ( $ENV{BIGDOOR_TEST_SAVE_RESPONSES} ) {
        unless ( -d $response_directory ) {
            mkdir $response_directory;
        }
    }
    if ( !$ENV{BIGDOOR_TEST_SAVE_RESPONSES} && !$ENV{BIGDOOR_TEST_LIVESERVER} ) {
        unless ( -d $response_directory ) {
            return 1;
        }
    }
    return 0;
}

sub get_username {
    my $username;

    my $username_filename =
      catfile( $response_directory, sprintf( "%s_username.txt", basename( $PROGRAM_NAME ) ) );

    if ( $ENV{BIGDOOR_TEST_SAVE_RESPONSES} || $ENV{BIGDOOR_TEST_LIVESERVER} ) {
        $username = join '', map { ( "a" .. "z" )[rand 26] } 1 .. 8;

        if ( $ENV{BIGDOOR_TEST_SAVE_RESPONSES} ) {
            if ( -d $response_directory ) {
                open( my $fh, '>', $username_filename )
                  or die 'unable to open file for writing:', $!;
                print $fh $username;
                close $fh;
            }
        }
    }
    else {
        if ( -d $response_directory ) {
            $username = slurp( $username_filename );
        }
    }
    return $username;
} ## end sub get_username
1;
