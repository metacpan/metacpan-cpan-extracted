use strict;
use warnings FATAL => 'all';
no warnings::illegalproto;

use Test::More 0.88;

use HTTP::Request::Common qw(GET POST);
use Web::Dispatch;
use HTTP::Response;
use Web::Dispatch::Predicates 'match_true';

my @dispatch;

{
    use Web::Simple 'MiscTest';

    package MiscTest;
    sub dispatch_request { @dispatch }
    sub string_method { [ 999, [], [""] ]; }

    sub can {
        die "Passed undef to can, this blows up on 5.8" unless defined($_[1]);
        shift->SUPER::can(@_)
    }
}

my $app = MiscTest->new;
sub run_request { $app->run_test_request( @_ ); }

string_method_name();
app_is_non_plack();
app_is_object();
app_is_just_sub();
plack_app_return();
broken_route_def();
invalid_psgi_responses();
middleware_as_only_route();
route_returns_middleware_plus_extra();
route_returns_undef();
matcher_nonsub_pair();
matcher_undef_method();

done_testing();

sub string_method_name {
    @dispatch = ( '/' => "string_method" );

    my $get = run_request( GET => 'http://localhost/' );

    cmp_ok $get->code, '==', 999, "a dispatcher that's a string matching a method on the dispatch object gets executed";
}

sub app_is_non_plack {

    my $r = HTTP::Response->new( 999 );

    my $d = Web::Dispatch->new( dispatch_app => $r );
    eval { $d->call };

    like $@, qr/No idea how we got here with HTTP::Response/,
      "Web::Dispatch dies when run with an app() that is a non-PSGI object";
    undef $@;
}

sub app_is_object {
    {

        package ObjectApp;
        use Moo;
        sub to_app { [ 999, [], ["ok"] ] }
    }

    my $o = ObjectApp->new;
    my $d = Web::Dispatch->new( dispatch_object => $o );
    my $res = $d->call;

    cmp_ok $res->[0], '==', 999, "Web::Dispatch can dispatch properly, given only an object with to_app method";
}

sub app_is_just_sub {
    my $d = Web::Dispatch->new( dispatch_app => sub () { [ 999, [], ["ok"] ] } );
    my $res = $d->call( {} );

    cmp_ok $res->[0], '==', 999,
      "Web::Dispatch can dispatch properly, given only an app that's just a sub, with no object involved";
}

sub plack_app_return {
    {

        package FauxPlackApp;
        sub new { bless {}, $_[0] }

        sub to_app {
            return sub {
                [ 999, [], [""] ];
            };
        }
    }

    @dispatch = (
        sub (/) {
            FauxPlackApp->new;
        }
    );

    my $get = run_request( GET => 'http://localhost/' );

    cmp_ok $get->code, '==', 999,
      "when a route returns a thing that look like a Plack app, the web app redispatches to that thing";
}

sub broken_route_def {

    @dispatch = ( '/' => "" );

    my $get = run_request( GET => 'http://localhost/' );

    cmp_ok $get->code, '==', 500, "a route definition by hash that doesn't pair a sub with a route dies";
    like $get->content, qr[No idea how we got here with /], "the error message points out the broken definition";
}

sub invalid_psgi_responses {
    undef $@;

    my @responses = (
        [ [ sub { } ], "an arrayref with a single sub in it" ],
        [ ["moo"], "an arrayref with a scalar that is not a sub" ],
        [ bless( {}, "FauxObject" ), "an object without to_app method" ],
    );

    for my $response ( @responses ) {
        @dispatch = ( sub (/) { $response->[0] } );

        my $message = sprintf(
            "if a route returns %s, then that is returned as a response by WD, causing HTTP::Message::PSGI to choke",
            $response->[1]
        );

        # Somewhere between 1.0028 and 1.0031 Plack changed so that the
        # FauxObject case became a 500 rather than a die; in case it later does
        # the same thing for other stuff, just accept either sort of error

        my $res = eval { run_request( GET => 'http://localhost/' ) };

        if ($res) {
          ok $res->is_error, $message;
        } else {
          like $@, qr/Can't call method "request" on an undefined value .*MockHTTP/, $message;
        }
        undef $@;
    }
}

sub middleware_as_only_route {
    @dispatch = ( bless {}, "Plack::Middleware" );

    my $get = run_request( GET => 'http://localhost/' );

    cmp_ok $get->code, '==', 500, "a route definition consisting of only a middleware causes a bail";
    like $get->content, qr[Multiple results but first one is a middleware \(Plack::Middleware=],
      "the error message mentions the middleware class";
}

sub route_returns_middleware_plus_extra {
    @dispatch = (
        sub (/) {
            return ( bless( {}, "Plack::Middleware" ), "" );
        }
    );

    my $get = run_request( GET => 'http://localhost/' );

    cmp_ok $get->code, '==', 500, "a route returning a middleware and at least one other variable causes a bail";
    like $get->content,
      qr[Multiple results but first one is a middleware \(Plack::Middleware=],
      "the error message mentions the middleware class";
}

sub route_returns_undef {
    @dispatch = (
        sub (/) {
            (
                sub(/) {
                    undef;
                },
                sub(/) {
                    [ 900, [], [""] ];
                }
            );
        },
        sub () {
            [ 400, [], [""] ];
        }
    );

    my $get = run_request( GET => 'http://localhost/' );

    cmp_ok $get->code, '==', 900, "a route that returns undef causes WD to ignore it and resume dispatching";
}

sub matcher_nonsub_pair {
    @dispatch = ( match_true() => 5 );

    my $get = run_request( GET => 'http://localhost/' );

    cmp_ok $get->code, '==', 500, "a route definition that pairs a WD::Matcher a non-sub dies";
    like $get->content, qr[No idea how we got here with Web::Dispatch::M],
      "the error message points out the broken definition";
}

sub matcher_undef_method {
    @dispatch = ( 'GET', undef );

    my $get = run_request( GET => 'http://localhost/' );

    cmp_ok $get->code, '==', 500, "a route definition that pairs a WD::Matcher a non-sub dies";
    like $get->content, qr[No idea how we got here with GET],
      "the error message points out the broken definition";
}
