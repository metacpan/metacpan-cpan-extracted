#!/usr/bin/env perl -w

use strict;
use Test::More;
use Test::Deep;
use Test::Mountebank::Response::Is;
use JSON::Tiny qw(decode_json);
use File::Temp;
use Test::Exception;

subtest 'string body' => sub  {
    my $is = Test::Mountebank::Response::Is->new(
        status_code => 201,
        headers => {
            Location => "http://localhost:4545/customers/123",
            Content_Type => "application/xml"
        },
        body => '<customer><email>customer@test.com</email></customer>'
    );

    my $expect_json = {
        is => {
            statusCode => 201,
            headers => {
                Location => "http://localhost:4545/customers/123",
                "Content-Type" => "application/xml"
            },
            body => '<customer><email>customer@test.com</email></customer>'
        }
    };
    cmp_deeply( $is->as_hashref(), $expect_json );
};

subtest 'hashref/json body' => sub  {
    my $is = Test::Mountebank::Response::Is->new(
        status_code => 201,
        headers => {
            Location => "http://localhost:4545/customers/123",
            Content_Type => "application/xml"
        },
        body => { foo => 'bar' },
    );

    my $expect_json = {
        is => {
            statusCode => 201,
            headers => {
                Location => "http://localhost:4545/customers/123",
                "Content-Type" => "application/xml"
            },
            body => { foo => 'bar' },
        }
    };
    cmp_deeply( $is->as_hashref(), $expect_json );
};

subtest 'can get body from file' => sub  {
    my $html = qq{<html>\n<div class="foo">\n</div>\n</html>};
    my $tmp = File::Temp->new(SUFFIX => '.html');
    print $tmp $html;
    $tmp->close();
    my $is = Test::Mountebank::Response::Is->new(
        status_code    => 200,
        body_from_file => "$tmp",
    );

    my $expect_json = {
        is => {
            body       => $html,
            statusCode => 200,
        },
    };
    cmp_deeply( $is->as_hashref(), $expect_json );
};

subtest 'croaks on empty body' => sub  {
    my $tmp = File::Temp->new(SUFFIX => '.html');
    dies_ok { Test::Mountebank::Response::Is->new(
            status_code    => 200,
            body_from_file => "$tmp") };
};

subtest 'content type shortcut' => sub  {
    my $is = Test::Mountebank::Response::Is->new(
        status_code => 200,
        content_type => 'text/css',
    );

    is($is->headers->header('Content_Type'), 'text/css');
    is($is->content_type, 'text/css');
};

subtest 'croaks on invalid content type' => sub  {
    dies_ok { Test::Mountebank::Response::Is->new(
            status_code    => 200,
            content_type => 'text/bazqux',
        )};
};

done_testing();
