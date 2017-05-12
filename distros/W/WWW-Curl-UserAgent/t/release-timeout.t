
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

use Test::More tests => 5;

use HTTP::Request;
use Test::Webserver;
use WWW::Curl::UserAgent;

Test::Webserver->start_webserver_daemon;

my $base_url = 'http://localhost:3000';

{
    note 'request timeout';

    my $ua  = WWW::Curl::UserAgent->new;
    my $res = $ua->request(
        HTTP::Request->new( GET => "$base_url/sleep/1" ),
        connect_timeout => 1,
        timeout         => 1,
    );

    ok $res;
    is $res->code,    500;
    is $res->message, 'Timeout was reached';
}

{
    note 'add_request timeout';

    my $ua = WWW::Curl::UserAgent->new;
    $ua->add_request(
        timeout         => 1,
        connect_timeout => 1,
        request         => HTTP::Request->new( GET => "$base_url/sleep/1" ),
        on_success      => sub { fail },
        on_failure      => sub {
            my ( $req, $err, $err_desc ) = @_;
            is $err,      'Timeout was reached';
            ok $err_desc, $err_desc;
        }
    );
    $ua->perform;
}

Test::Webserver->stop_webserver_daemon;
