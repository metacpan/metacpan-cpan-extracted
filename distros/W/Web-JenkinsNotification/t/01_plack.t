#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 3;
use Plack::Builder;
use Plack::Test;
use Web::JenkinsNotification;
use HTTP::Request::Common;
use HTTP::Response;
use File::Read;

test_psgi 
    app => builder {
        enable "+Web::JenkinsNotification";
        sub {
            my $env = shift;

            ok($env->{"jenkins.notification"}, 'found notification');
            
            my $response = Plack::Response->new(200);
            $response->body('{ success: 1 }');
            return $response->finalize;
        };
    },
    client => sub {
        my $cb  = shift;
        my $json = read_file 't/data/notification.json';

        ok $json, 'got json';

        # URI-escape
        my $res = $cb->(POST "http://localhost/" , Content => $json );
        ok $res, 'response';
    };

done_testing;
