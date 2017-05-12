use strict;
use warnings;
use Test2::Bundle::Extended;
use Test2::API qw/intercept/;

use Test2::Tools::EventDumper;

my $events = intercept {
    ok(1, 'a');
    ok(2, 'b');

    ok(0, 'fail');

    subtest foo => sub {
        ok(1, 'a');
        ok(2, 'b');
    };

    note "XX'\"{/[(XX";

    diag "YYY";
};

delete $events->[-2]->{trace};

my $dump = dump_events $events;
note $dump;

is("$dump\n", <<'EOT', "Output matches expectations");
array {
    event Ok => sub {
        call name => 'a';
        call pass => 1;
        call effective_pass => 1;

        prop file => match qr{\Qbasic.t\E$};
        prop line => 9;
    };

    event Ok => sub {
        call name => 'b';
        call pass => 1;
        call effective_pass => 1;

        prop file => match qr{\Qbasic.t\E$};
        prop line => 10;
    };

    event Ok => sub {
        call name => 'fail';
        call pass => 0;
        call effective_pass => 0;

        prop file => match qr{\Qbasic.t\E$};
        prop line => 12;
    };

    event Diag => sub {
        call message => match qr{^\n?Failed test};

        prop file => match qr{\Qbasic.t\E$};
        prop line => 12;
    };

    event Subtest => sub {
        call name => 'foo';
        call pass => 1;
        call effective_pass => 1;

        prop file => match qr{\Qbasic.t\E$};
        prop line => 17;

        call subevents => array {
            event Ok => sub {
                call name => 'a';
                call pass => 1;
                call effective_pass => 1;

                prop file => match qr{\Qbasic.t\E$};
                prop line => 15;
            };

            event Ok => sub {
                call name => 'b';
                call pass => 1;
                call effective_pass => 1;

                prop file => match qr{\Qbasic.t\E$};
                prop line => 16;
            };

            event Plan => sub {
                call max => 2;

                prop file => match qr{\Qbasic.t\E$};
                prop line => 17;
            };
            end();
        };
    };

    event Note => {message => 'XX\'"{/[(XX'};

    event Diag => sub {
        call message => 'YYY';

        prop file => match qr{\Qbasic.t\E$};
        prop line => 21;
    };
    end();
}
EOT

done_testing;
