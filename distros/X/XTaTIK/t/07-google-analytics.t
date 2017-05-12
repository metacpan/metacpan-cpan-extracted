#!perl

use Test::More;

unless ( $ENV{XTATIK_TESTING} ) {
    diag 'Set XTATIK_TESTING env var to true, to run the tests';
    ok 1; done_testing; exit;
}

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
eval 'use Test::XTaTIK';
use Mojo::DOM;

{
    $t->app->xtext('google_analytics', 0 );

    $t->get_ok('/')
        ->content_unlike(
            qr{GoogleAnalyticsObject},
            'GA code disabled',
        );

    $t->app->xtext('google_analytics', 'UA-00000000-00' );
    $t->get_ok('/products')
        ->content_like(
            qr{\Qga('create', 'UA-00000000-00', 'auto');\E},
            'GA code enabled',
        );
}

done_testing();
