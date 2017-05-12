
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib", "$FindBin::Bin/../../lib";

use Test::More tests => 4;

use HTTP::Request;
use Test::Webserver;
use WWW::Curl::UserAgent;

Test::Webserver->start_webserver_daemon;

my $base_url = 'http://localhost:3000';

{
    note 'test redirect disabled';

    my $ua = WWW::Curl::UserAgent->new;
    $ua->add_request(
        request    => HTTP::Request->new( GET => "$base_url/redirect/1" ),
        on_failure => sub                     { fail },
        on_success => sub {
            my ( $req, $res ) = @_;
            is $res->code, 301, 'automatic redirect disabled';
        }
    );
    $ua->perform;
}

{
    note 'test redirect enabled';

    my $ua = WWW::Curl::UserAgent->new;
    $ua->add_request(
        followlocation => 1,
        request        => HTTP::Request->new( GET => "$base_url/redirect/1" ),
        on_failure     => sub { fail },
        on_success     => sub {
            my ( $req, $res ) = @_;
            is $res->code, 204, 'automatic redirect enabled';
        }
    );
    $ua->perform;
}

{
    note 'test redirect error';

    my $ua = WWW::Curl::UserAgent->new;
    $ua->add_request(
        followlocation => 1,
        max_redirects  => 1,
        request        => HTTP::Request->new( GET => "$base_url/redirect/10" ),
        on_success     => sub { fail },
        on_failure     => sub {
            my ( $req, $err, $err_desc ) = @_;
            is $err,      'Number of redirects hit maximum amount';
            ok $err_desc, $err_desc;
        },
    );
    $ua->perform;
}

Test::Webserver->stop_webserver_daemon;
