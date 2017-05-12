use strict;
use warnings FATAL => 'all';

use Test::More (
  eval { require HTTP::Request::AsCGI }
    ? 'no_plan'
    : (skip_all => 'No HTTP::Request::AsCGI')
);

use HTTP::Request::Common qw(GET POST);

my $app = StreamTest->new;

ok run_request( $app, GET 'http://localhost/' )->is_success;
is run_request( $app, GET 'http://localhost/' )->content, "foo";

sub run_request {
    my ( $app, $request ) = @_;
    my $c = HTTP::Request::AsCGI->new( $request )->setup;
    $app->run;
    $c->restore;
    return $c->response;
}

{

    package StreamTest;
    use Web::Simple;

    sub dispatch_request {

        sub (GET) {
            [
                sub {
                    my $respond = shift;
                    my $writer = $respond->( [ 200, [ "Content-type" => "text/plain" ] ] );
                    $writer->write( 'f' );
                    $writer->write( 'o' );
                    $writer->write( 'o' );
                  }
            ];
        },;
    }
}
