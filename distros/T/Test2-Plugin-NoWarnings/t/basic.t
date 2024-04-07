use strict;
use warnings;

# We load this here _before_ Test2::Plugin::NoWarnings because if we run tests
# with 5.18, we get a warning from the version of Module::Pluggable shipped in
# the 5.18 core. The warning says that Module::Pluggable will be removed from
# the core. That warning causes our tests to fail.
#
# Module::Pluggable is used by the Test2::API::InterceptResult::Event package.
use Module::Pluggable;

use Test2::API qw( intercept );
use Test2::V0;
use Test2::Plugin::NoWarnings;

{
    my $events = intercept {
        ok(1);
        warn 'Oh noes!';
        ok(2);
    };

    is(
        $events,
        array {
            event Ok => sub {
                call pass => T();
            };
            event Warning => sub {
                call facets => hash {
                    field assert => object {
                        call pass => F();
                        call details => match
                            qr/^Unexpected warning: Oh noes!/,;
                    }
                };
                call warning => match qr/^Unexpected warning: Oh noes!/;
            };
            event Ok => sub {
                call pass => T();
            };
            end();
        }
    );
}

{
    my $events = intercept {
        ok(1);
        subtest 'subt' => sub {
            warn 'Oh noes!';
            ok(2);
        };
    };

    is(
        $events,
        array {
            event Ok => sub {
                call pass => T();
            };
            event Subtest => sub {
                call pass      => F();
                call subevents => array {
                    event Warning => sub {
                        call facets => hash {
                            field assert => object {
                                call pass => F();
                                call details => match
                                    qr/^Unexpected warning: Oh noes!/,;
                            }
                        }
                    };
                    event Ok => sub {
                        call pass => T();
                    };
                    event Plan => sub {
                        call max => 2;
                    };
                    end();
                };
            };
            event Diag => sub {
                call message => match qr{^\n?Failed test};
            };
            end();
        }
    );
}

done_testing();
