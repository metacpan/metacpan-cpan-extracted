use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use lib "$RealBin/../lib";

use Cwd qw(fastcwd);
use File::Basename qw(basename dirname);
use File::Spec;
use File::Temp qw(tempfile);
use HTTP::Headers::Fast;
use HTTP::Request::Common qw(GET);
use IO::File;
use IO::String;

use WebDyne;
use WebDyne::Request::Fake;


BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
}


my $source_fn=File::Spec->catfile(dirname($RealBin), 't.error', 'error_basic.psp');
my $source_fh=IO::File->new($source_fn, 'r') || die "unable to open '$source_fn', $!";
my $source_text=do {
    local $/;
    <$source_fh>;
};
$source_fh->close();

my ($fixture_fh, $fixture_fn)=tempfile('error_handler_XXXX', DIR => $RealBin, SUFFIX => '.psp', UNLINK => 1);
print {$fixture_fh} $source_text;
close($fixture_fh) || die "unable to close '$fixture_fn', $!";
my $fixture_cn=basename($fixture_fn);


sub body_matches_error {
    my ($body)=@_;
    return (($body =~ /Bang !/) && ($body =~ /Error/i));
}


sub fake_error {
    WebDyne->init();
    my $body=q();
    my $body_fh=IO::String->new($body);
    my $r=WebDyne::Request::Fake->new(
        filename   => $fixture_fn,
        select     => $body_fh,
        noheader   => 1,
        headers_in => HTTP::Headers::Fast->new(),
    );
    my $status=WebDyne->handler($r);
    $body_fh->close();
    return ($status, $r->content_type(), $body);
}


sub psgi_error {
    require WebDyne::PSGI;
    require Plack::Test;
    WebDyne->init();
    my $app_cr=WebDyne::PSGI->new(root => $RealBin)->to_app();
    my $res=Plack::Test->create($app_cr)->request(GET("/$fixture_cn"));
    return ($res->code(), ($res->header('Content-Type') || q()), $res->decoded_content());
}


sub pagi_error {
    require WebDyne::PAGI;
    require PAGI::Test::Client;
    WebDyne->init();
    my $app_cr=WebDyne::PAGI->new(root => $RealBin)->to_app();
    my $res=PAGI::Test::Client->new(app => $app_cr)->get("/$fixture_cn");
    return ($res->status(), ($res->header('content-type') || q()), $res->content());
}


sub apache_error {
    require Apache::TestRequest;
    require apache_harness_helper;
    my $runner;
    my @result;
    my $ok=eval {
        $runner=apache_harness_helper::startup();
        my $body=Apache::TestRequest::GET_BODY($fixture_cn);
        @result=(undef, q(), $body);
        1;
    };
    my $err=$@;
    apache_harness_helper::shutdown($runner) if $runner;
    die $err unless $ok;
    return @result;
}


my ($fake_status, $fake_ctype, $fake_body)=fake_error();
ok($fake_status && $fake_status >= 500, 'fake handler returns an error status');
ok(($fake_ctype || q()) =~ m{text/(?:plain|html)}i, 'fake handler marks the response as error content');


SKIP: {
    eval { require Plack::Test; 1 } || skip "Skipping PSGI error test: missing Plack::Test", 2;
    my ($psgi_status, $psgi_ctype, $psgi_body)=psgi_error();
    ok($psgi_status && $psgi_status >= 500, 'PSGI handler returns an error status');
    ok(body_matches_error($psgi_body), 'PSGI handler emits a recognisable error body');
}


SKIP: {
    eval { require PAGI::Test::Client; 1 } || skip "Skipping PAGI error test: missing PAGI::Test::Client", 2;
    my ($pagi_status, $pagi_ctype, $pagi_body)=pagi_error();
    ok($pagi_status && $pagi_status >= 500, 'PAGI handler returns an error status');
    ok(body_matches_error($pagi_body), 'PAGI handler emits a recognisable error body');
}


SKIP: {
    require apache_harness_helper;
    my @missing=apache_harness_helper::apache_prereq_missing();
    skip 'Skipping Apache error test: missing ' . join(', ', @missing), 1 if @missing;
    skip 'Skipping Apache error test: cannot run tests as root user', 1 if $> == 0;
    my (undef, undef, $body)=eval { apache_error() };
    if ($@ && apache_harness_helper::apache_startup_unavailable($@)) {
        skip 'Skipping Apache error test: sockets not available in this environment', 1;
    }
    ok(body_matches_error($body), 'Apache handler emits a recognisable error body');
}


done_testing();
