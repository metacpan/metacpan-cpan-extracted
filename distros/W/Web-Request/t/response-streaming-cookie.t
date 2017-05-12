#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Request;

{
    my $app = sub {
        my $env = shift;
        my $req = Web::Request->new_from_env($env);
        my $res = $req->new_response(sub {
            my $responder = shift;
            $responder->([ 200, ['X-Thing' => 'stuff'], ["foo"] ]);
        });

        $res->cookies->{t1} = { value => "bar", domain => '.example.com', path => '/cgi-bin' };
        $res->cookies->{t2} = { value => "xxx yyy", expires => time + 3600 };
        $res->cookies->{t3} = { value => "123123", "max-age" => 15 };

        $res->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is(scalar($res->header('X-Thing')), 'stuff');

            my @v = sort $res->header('Set-Cookie');
            is $v[0], "t1=bar; domain=.example.com; path=/cgi-bin";
            like $v[1], qr/t2=xxx%20yyy; expires=\w+, \d+-\w+-\d+ \d\d:\d\d:\d\d GMT/;
            is $v[2], "t3=123123; max-age=15";

            is($res->content, "foo");
        }
    };
}

{
    my $app = sub {
        my $env = shift;
        my $req = Web::Request->new_from_env($env);
        my $res = $req->new_response(sub {
            my $responder = shift;
            my $writer = $responder->([ 200, ['X-Thing' => 'stuff'] ]);
            $writer->write("foo");
            $writer->write("bar");
            $writer->close;
        });

        $res->cookies->{t1} = { value => "bar", domain => '.example.com', path => '/cgi-bin' };
        $res->cookies->{t2} = { value => "xxx yyy", expires => time + 3600 };
        $res->cookies->{t3} = { value => "123123", "max-age" => 15 };

        $res->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is(scalar($res->header('X-Thing')), 'stuff');

            my @v = sort $res->header('Set-Cookie');
            is $v[0], "t1=bar; domain=.example.com; path=/cgi-bin";
            like $v[1], qr/t2=xxx%20yyy; expires=\w+, \d+-\w+-\d+ \d\d:\d\d:\d\d GMT/;
            is $v[2], "t3=123123; max-age=15";

            is($res->content, "foobar");
        }
    };
}

{
    use utf8;
    my $app = sub {
        my $env = shift;
        my $req = Web::Request->new_from_env($env);
        my $res = $req->new_response(sub {
            my $responder = shift;
            $responder->([ 200, ['X-Thing' => 'stuff'], ["café"] ]);
        });

        $res->cookies->{t1} = { value => "bar", domain => '.example.com', path => '/cgi-bin' };
        $res->cookies->{t2} = { value => "xxx yyy", expires => time + 3600 };
        $res->cookies->{t3} = { value => "123123", "max-age" => 15 };

        $res->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is(scalar($res->header('X-Thing')), 'stuff');

            my @v = sort $res->header('Set-Cookie');
            is $v[0], "t1=bar; domain=.example.com; path=/cgi-bin";
            like $v[1], qr/t2=xxx%20yyy; expires=\w+, \d+-\w+-\d+ \d\d:\d\d:\d\d GMT/;
            is $v[2], "t3=123123; max-age=15";

            is($res->content, "caf\xe9");
        }
    };
}

{
    use utf8;

    my $app = sub {
        my $env = shift;
        my $req = Web::Request->new_from_env($env);
        my $res = $req->new_response(sub {
            my $responder = shift;
            my $writer = $responder->([ 200, ['X-Thing' => 'stuff'] ]);
            $writer->write("ca");
            $writer->write("fé");
            $writer->close;
        });

        $res->cookies->{t1} = { value => "bar", domain => '.example.com', path => '/cgi-bin' };
        $res->cookies->{t2} = { value => "xxx yyy", expires => time + 3600 };
        $res->cookies->{t3} = { value => "123123", "max-age" => 15 };

        $res->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is(scalar($res->header('X-Thing')), 'stuff');

            my @v = sort $res->header('Set-Cookie');
            is $v[0], "t1=bar; domain=.example.com; path=/cgi-bin";
            like $v[1], qr/t2=xxx%20yyy; expires=\w+, \d+-\w+-\d+ \d\d:\d\d:\d\d GMT/;
            is $v[2], "t3=123123; max-age=15";

            is($res->content, "caf\xe9");
        }
    };
}

{
    use utf8;
    my $app = sub {
        my $env = shift;
        my $req = Web::Request->new_from_env($env);
        $req->encoding('UTF-8');
        my $res = $req->new_response(sub {
            my $responder = shift;
            $responder->([ 200, ['X-Thing' => 'stuff'], ["café"] ]);
        });

        $res->cookies->{t1} = { value => "bar", domain => '.example.com', path => '/cgi-bin' };
        $res->cookies->{t2} = { value => "xxx yyy", expires => time + 3600 };
        $res->cookies->{t3} = { value => "123123", "max-age" => 15 };

        $res->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is(scalar($res->header('X-Thing')), 'stuff');

            my @v = sort $res->header('Set-Cookie');
            is $v[0], "t1=bar; domain=.example.com; path=/cgi-bin";
            like $v[1], qr/t2=xxx%20yyy; expires=\w+, \d+-\w+-\d+ \d\d:\d\d:\d\d GMT/;
            is $v[2], "t3=123123; max-age=15";

            is($res->content, "caf\xc3\xa9");
        }
    };
}

{
    use utf8;

    my $app = sub {
        my $env = shift;
        my $req = Web::Request->new_from_env($env);
        $req->encoding('UTF-8');
        my $res = $req->new_response(sub {
            my $responder = shift;
            my $writer = $responder->([ 200, ['X-Thing' => 'stuff'] ]);
            $writer->write("ca");
            $writer->write("fé");
            $writer->close;
        });

        $res->cookies->{t1} = { value => "bar", domain => '.example.com', path => '/cgi-bin' };
        $res->cookies->{t2} = { value => "xxx yyy", expires => time + 3600 };
        $res->cookies->{t3} = { value => "123123", "max-age" => 15 };

        $res->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");

            ok($res->is_success)
                || diag($res->status_line . "\n" . $res->content);

            is(scalar($res->header('X-Thing')), 'stuff');

            my @v = sort $res->header('Set-Cookie');
            is $v[0], "t1=bar; domain=.example.com; path=/cgi-bin";
            like $v[1], qr/t2=xxx%20yyy; expires=\w+, \d+-\w+-\d+ \d\d:\d\d:\d\d GMT/;
            is $v[2], "t3=123123; max-age=15";

            is($res->content, "caf\xc3\xa9");
        }
    };
}

done_testing;
