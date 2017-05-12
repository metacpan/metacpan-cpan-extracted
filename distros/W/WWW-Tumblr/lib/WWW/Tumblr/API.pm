package WWW::Tumblr::API;

use strict;
use warnings;

use Moose;
use JSON 'decode_json';
use Moose::Exporter;
Moose::Exporter->setup_import_methods(with_caller => ['tumblr_api_method']);
use WWW::Tumblr::ResponseError;

sub tumblr_api_method ($$) {
    my $class = Moose::Meta::Class->initialize( shift );
    my $method_name = $_[0];
    my $method_spec = $_[1];

    my $sub = sub {
        my $self = shift;
        my $args = { @_ };

        my ( $http_method, $auth_method, $req_params, $url_param ) = @{ $method_spec };
       
        my $kind = lc( pop( @{ [ split '::', ref $self ] }));

        my $response = $self->_tumblr_api_request({
            auth        => $auth_method,
            http_method => $http_method,
            url_path    => $kind . '/' . ( $kind eq 'blog' ? $self->base_hostname . '/' : '' ) .
                            join('/', split /_/, $method_name) .
                            ( defined $url_param && defined $args->{ $url_param } ?
                                '/' . delete( $args->{ $url_param } ) : ''
                            ),
            extra_args  => $args,
        });

        if ( $response->is_success || ( $response->code == 301 && $method_name eq 'avatar') ) {
            return decode_json($response->decoded_content)->{response};
        } else {
            $self->error( WWW::Tumblr::ResponseError->new(
                response => $response
            ) );
            return;
        }
    };

    $class->add_method($method_name, $sub );

}

1;
