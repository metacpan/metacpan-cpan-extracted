use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use lib "$RealBin/../lib";
use pagi_compat_helper qw(pagi_skip_reason);

use File::Spec;
use HTTP::Headers::Fast;
use HTTP::Request::Common qw(GET);
use IO::String;

use WebDyne;
use WebDyne::Request::Fake;


BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
}


my $missing_cn='does-not-exist-webdyne-404.psp';
my $missing_fn=File::Spec->catfile($RealBin, $missing_cn);


sub fake_not_found {
    WebDyne->init();
    my $body=q();
    my $body_fh=IO::String->new($body);
    my $r=WebDyne::Request::Fake->new(
        filename   => $missing_fn,
        select     => $body_fh,
        noheader   => 1,
        headers_in => HTTP::Headers::Fast->new(),
    );
    my $status=WebDyne->handler($r);
    $body_fh->close();
    return ($status, $r->status(), $body);
}


sub psgi_not_found {
    require WebDyne::PSGI;
    require Plack::Test;
    WebDyne->init();
    my $app_cr=WebDyne::PSGI->new(root => $RealBin)->to_app();
    my $res=Plack::Test->create($app_cr)->request(GET("/$missing_cn"));
    return ($res->code(), $res->decoded_content());
}


sub pagi_not_found {
    require WebDyne::PAGI;
    require PAGI::Test::Client;
    WebDyne->init();
    my $app_cr=WebDyne::PAGI->new(root => $RealBin)->to_app();
    my $res=PAGI::Test::Client->new(app => $app_cr)->get("/$missing_cn");
    return ($res->status(), $res->content());
}


sub apache_not_found {
    require Apache::TestRequest;
    require apache_harness_helper;
    my $runner;
    my @result;
    my $ok=eval {
        $runner=apache_harness_helper::startup();
        my $status=Apache::TestRequest::GET_RC("/$missing_cn");
        my $body=Apache::TestRequest::GET_BODY("/$missing_cn");
        @result=($status, $body);
        1;
    };
    my $err=$@;
    apache_harness_helper::shutdown($runner) if $runner;
    die $err unless $ok;
    return @result;
}


my ($fake_status, $fake_rstatus, $fake_body)=fake_not_found();
is($fake_status, 404, 'fake handler returns 404 for missing file');
is($fake_rstatus, 404, 'fake request status is 404 for missing file');


SKIP: {
    eval { require Plack::Test; 1 } || skip "Skipping PSGI 404 test: missing Plack::Test", 2;
    my ($psgi_status, $psgi_body)=psgi_not_found();
    is($psgi_status, 404, 'PSGI handler returns 404 for missing file');
    like($psgi_body, qr/Not Found|File not found/i, 'PSGI handler emits not found body');
}


SKIP: {
    my $pagi_skip=pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::Test::Client PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    skip "Skipping PAGI 404 test: $pagi_skip", 2
        if $pagi_skip;
    eval { require WebDyne::PAGI; require PAGI::Test::Client; 1 } || skip "Skipping PAGI 404 test: $@", 2;
    my ($pagi_status, $pagi_body)=pagi_not_found();
    is($pagi_status, 404, 'PAGI handler returns 404 for missing file');
    like($pagi_body, qr/Not Found|File not found/i, 'PAGI handler emits not found body');
}


SKIP: {
    require apache_harness_helper;
    my @missing=apache_harness_helper::apache_prereq_missing();
    skip 'Skipping Apache 404 test: missing ' . join(', ', @missing), 2 if @missing;
    skip 'Skipping Apache 404 test: cannot run tests as root user', 2 if $> == 0;
    my ($apache_status, $apache_body)=eval { apache_not_found() };
    if ($@ && apache_harness_helper::apache_startup_unavailable($@)) {
        skip 'Skipping Apache 404 test: sockets not available in this environment', 2;
    }
    is($apache_status, 404, 'Apache handler returns 404 for missing file');
    like($apache_body, qr/Not Found|File not found/i, 'Apache handler emits not found body');
}


done_testing();
