
use Test;
BEGIN { plan tests => 5 };

use base 'Waft';
use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

$ENV{REQUEST_METHOD} = 'GET';
$ENV{SCRIPT_NAME} = '/test.cgi';

my $self = __PACKAGE__->new;

sub create_query_obj {

    require CGI;

    return CGI->new('s=test.html&v=foo-bar&baz=');
}

sub global__baz { }

$self->set_response_headers('Test: foo=bar; baz');

$self->initialize;

ok( $self->url eq 'test.cgi' );
ok( $self->page eq 'test.html' );
ok( $self->{foo} eq 'bar' );
ok( $self->action eq 'global__baz' );
ok( $self->get_response_headers == 0 );
