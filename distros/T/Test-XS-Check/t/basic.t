use strict;
use warnings;

use Test2::API qw( intercept );
use Test2::V0;

use Test::XS::Check qw( xs_ok );

{
    my $events = intercept { xs_ok('t/share/DateTime.xs') };
    is(
        $events,
        array {
            event Ok => sub {
                call name => 'XS check for t/share/DateTime.xs';
                call pass => 1;
            };
            end();
        },
        'got expected events for XS file which passes checks'
    );
}

{
    my $events = intercept { xs_ok('t/share/Bad.xs') };

    is(
        $events,
        array {
            event Ok => sub {
                call name => 'XS check for t/share/Bad.xs';
                call pass => 0;
            };
            event Diag => sub {
                call message => match qr{^\n?Failed test};
            };
            event Diag => sub {
                call message => 'str not a constant type at line 17';
            };
            event Diag => sub {
                call message =>
                    'len is not a STRLEN variable (int ) at line 17';
            };
            event Diag => sub {
                call message =>
                    q{Remove the 'Perl_' prefix from Perl_SvPV at line 17};

            };
            end();
        },
        'got expected events for XS file which fails checks'
    );
}

done_testing();
