
use Test;
BEGIN { plan tests => 2 };

use base 'Waft';
use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use English qw( -no_match_vars );

use lib 't';
require Waft::Test::STDERR;

if ($PERL_VERSION < 5.008001) {
    for ( 1 .. 2 ) {
        skip(1, q{It's tested only on 5.008001 or later about UTF-8});
    }

    exit;
}

require CGI;

if (CGI->VERSION < 3.21) {
    for ( 1 .. 2 ) {
        skip(1, q{Waft needs CGI 3.21 or later to use UTF-8});
    }

    exit;
}

__PACKAGE__->use_utf8;

{
    my $self = __PACKAGE__->new;

    local $ENV{REQUEST_METHOD} = 'GET';
    local $ENV{QUERY_STRING} = q{};

    my $stderr = Waft::Test::STDERR->new;

    $self->initialize_page;

    ok( length $stderr->get == 0 );
}

{
    my $self = __PACKAGE__->new;

    local $ENV{REQUEST_METHOD} = 'GET';
    local $ENV{QUERY_STRING} = 'p=utf8_test.html';

    $self->initialize_page;

    ok( not utf8::is_utf8( $self->get_page ) );
}
