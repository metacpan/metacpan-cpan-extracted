use strict;
use warnings;

use Test::More tests => 8 + 2;
use Test::NoWarnings;
use WWW::NOS::Open;

my $API_KEY         = $ENV{NOSOPEN_API_KEY} || q{TEST};
my $INVALID_API_KEY = q{INVALID};
my $MINUTE          = 60;

my $obj = WWW::NOS::Open->new($API_KEY);
my $e;

eval { $obj->get_radio_broadcasts( q{2010-01-01}, q{2010-01-15} ) };
$e = Exception::Class->caught('NOSOpenExceededRangeException');
is( $e, undef, q{not throwing range exceeded error string input} );

eval {
    $obj->get_radio_broadcasts(
        DateTime->new( year => 2010, month => 1, day => 1 ),
        DateTime->new( year => 2010, month => 1, day => 15 ),
    );
};
$e = Exception::Class->caught('NOSOpenExceededRangeException');
is( $e, undef, q{not throwing range exceeded error DateTime input} );
eval { $obj->get_radio_broadcasts( q{2010-01-01}, q{2010-01-16} ) };
$e = Exception::Class->caught('NOSOpenExceededRangeException');
is(
    $e->error,
    q{Date range exceeds maximum of 14 days},
    q{throwing range exceeded error string input}
);

eval {
    $obj->get_radio_broadcasts(
        DateTime->new( year => 2010, month => 1, day => 1 ),
        DateTime->new( year => 2010, month => 1, day => 16 ),
    );
};
$e = Exception::Class->caught('NOSOpenExceededRangeException');
is(
    $e->error,
    q{Date range exceeds maximum of 14 days},
    q{throwing range exceeded error DateTime input}
);

SKIP: {
    skip q{Server test. Set $ENV{NOSOPEN_SERVER} to run.}, 4
      unless $ENV{NOSOPEN_SERVER};
    eval { $obj->search(q{FORCED_bad_request}) };
    $e = Exception::Class->caught('NOSOpenBadRequestException');
    is( $e->error->{ shift @{ [ keys %{ $e->error } ] } }->{error}->{code},
        111, q{throwing BAD REQUEST error} );

    eval { $obj->search(q{FORCED_internal_server_error}) };
    $e = Exception::Class->caught('NOSOpenInternalServerErrorException');
    is(
        $e->error,
        q{Internal server error or no response recieved},
        q{throwing INTERNAL SERVER ERROR error}
    );

    eval { $obj->get_version; };
    $e = Exception::Class->caught('NOSOpenInternalServerErrorException')
      || Exception::Class->caught('NOSOpenUnauthorizedException');

    $obj->set_api_key($INVALID_API_KEY);
    eval { $obj->get_version; };
    $e = Exception::Class->caught('NOSOpenUnauthorizedException');
    is( $e->error->{ shift @{ [ keys %{ $e->error } ] } }->{error}->{code},
        201, q{throwing UNAUTHORIZED error} );

    $obj->set_api_key($API_KEY);
    my $request = 0;
    $e = undef;
    while ( !defined $e ) {
        diag( q{Pushing rate to limit } . $request++ );
        eval { $obj->get_version; };
        $e = Exception::Class->caught('NOSOpenForbiddenException');
    }
    is( $e->error->{ shift @{ [ keys %{ $e->error } ] } }->{error}->{code},
        301, q{throwing FORBIDDEN error} );
    diag(qq{Waiting $MINUTE seconds for rate to recover...});
    sleep $MINUTE;

}
my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
