use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use lib "$RealBin/../lib";
use pagi_compat_helper qw(pagi_skip_reason);

use Cwd qw(fastcwd);
use File::Basename qw(basename dirname);
use File::Spec;
use File::Temp qw(tempfile);
use HTTP::Headers::Fast;
use HTTP::Request::Common qw(GET);
use IO::File;
use IO::String;
use Capture::Tiny qw(capture);

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


sub run_error_case {
    my (%arg)=@_;
    my $handler=$arg{'handler'};
    my $fixture_dn=dirname($fixture_fn);
    my %code=(
        fake => <<'END_FAKE',
use IO::String;
use HTTP::Headers::Fast;
use WebDyne;
use WebDyne::Request::Fake;
my $body=q();
my $body_fh=IO::String->new($body);
WebDyne->init();
my $r=WebDyne::Request::Fake->new(
    filename   => $ENV{'WEBDYNE_TEST_ERROR_FIXTURE'},
    select     => $body_fh,
    noheader   => 1,
    headers_in => HTTP::Headers::Fast->new(),
);
my $status=WebDyne->handler($r);
$body_fh->close();
write_result($status, $r->content_type(), $body);
END_FAKE
        psgi => <<'END_PSGI',
use WebDyne::PSGI;
use Plack::Test;
use HTTP::Request::Common qw(GET);
WebDyne->init();
my $app_cr=WebDyne::PSGI->new(root => $ENV{'WEBDYNE_TEST_ERROR_ROOT'})->to_app();
my $res=Plack::Test->create($app_cr)->request(GET('/' . $ENV{'WEBDYNE_TEST_ERROR_CN'}));
write_result($res->code(), ($res->header('Content-Type') || q()), $res->decoded_content());
END_PSGI
        pagi => <<'END_PAGI',
use WebDyne::PAGI;
use PAGI::Test::Client;
WebDyne->init();
my $app_cr=WebDyne::PAGI->new(root => $ENV{'WEBDYNE_TEST_ERROR_ROOT'})->to_app();
my $res=PAGI::Test::Client->new(app => $app_cr)->get('/' . $ENV{'WEBDYNE_TEST_ERROR_CN'});
write_result($res->status(), ($res->header('content-type') || q()), $res->content());
END_PAGI
    );

    my $result_prefix=<<'END_PREFIX';
sub write_result {
    my ($status, $ctype, $body)=@_;
    open(my $out_fh, '>', $ENV{'WEBDYNE_TEST_RESULT_FN'}) ||
        die "unable to open result file '$ENV{WEBDYNE_TEST_RESULT_FN}', $!";
    print {$out_fh} "status=", ($status || q()), "\n";
    print {$out_fh} "ctype=", ($ctype || q()), "\n";
    print {$out_fh} "body_fn=", $ENV{'WEBDYNE_TEST_BODY_FN'}, "\n";
    close($out_fh) ||
        die "unable to close result file '$ENV{WEBDYNE_TEST_RESULT_FN}', $!";
    open(my $body_fh, '>', $ENV{'WEBDYNE_TEST_BODY_FN'}) ||
        die "unable to open body file '$ENV{WEBDYNE_TEST_BODY_FN}', $!";
    print {$body_fh} ($body || q());
    close($body_fh) ||
        die "unable to close body file '$ENV{WEBDYNE_TEST_BODY_FN}', $!";
}
END_PREFIX

    my ($result_fh, $result_fn)=tempfile('error_handler_result_XXXX', DIR => $fixture_dn, UNLINK => 1);
    close($result_fh) || die "unable to close '$result_fn', $!";
    my ($body_fh, $body_fn)=tempfile('error_handler_body_XXXX', DIR => $fixture_dn, UNLINK => 1);
    close($body_fh) || die "unable to close '$body_fn', $!";
    local %ENV=(
        %ENV,
        WEBDYNE_CONF               => '.',
        WEBDYNE_TEST_ERROR_FIXTURE => $fixture_fn,
        WEBDYNE_TEST_ERROR_ROOT    => $fixture_dn,
        WEBDYNE_TEST_ERROR_CN      => $fixture_cn,
        WEBDYNE_TEST_RESULT_FN     => $result_fn,
        WEBDYNE_TEST_BODY_FN       => $body_fn,
    );
    my ($out, $err, $wait_status)=capture {
        system($^X, '-Ilib', '-e', $result_prefix . $code{$handler});
    };
    my $exit=$wait_status >> 8;
    my $signal=$wait_status & 127;
    die "subprocess for $handler failed: exit=$exit signal=$signal wait=$wait_status stderr=$err" if $exit != 0;
    return {skip => "subprocess for $handler terminated by signal $signal on this Perl"} if $signal;

    open(my $result_fh_read, '<', $result_fn) ||
        die "unable to read result file '$result_fn', $!";
    my $result_text=do {
        local $/;
        <$result_fh_read>;
    };
    close($result_fh_read) || die "unable to close result file '$result_fn', $!";
    my %result=map {
        my ($k, $v)=split(/=/, $_, 2);
        $k => $v;
    } grep { length($_) } split(/\n/, $result_text);
    if ($result{'body_fn'}) {
        open(my $body_fh_read, '<', $result{'body_fn'}) ||
            die "unable to read body file '$result{body_fn}', $!";
        $result{'body'}=do {
            local $/;
            <$body_fh_read>;
        };
        close($body_fh_read) || die "unable to close body file '$result{body_fn}', $!";
    }
    if (!exists($result{'status'}) || !exists($result{'ctype'}) || !exists($result{'body'})) {
        diag("subprocess for $handler produced incomplete output; exit=$exit signal=$signal wait=$wait_status");
        diag("result file:\n$result_text");
        diag("stdout:\n$out") if length($out);
        diag("stderr:\n$err") if length($err);
    }
    return \%result;
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


SKIP: {
    my $result=run_error_case(handler => 'fake');
    skip $result->{'skip'}, 2 if $result->{'skip'};
    ok($result->{'status'} && $result->{'status'} >= 500, 'fake handler returns an error status');
    ok(($result->{'ctype'} || q()) =~ m{text/(?:plain|html)}i, 'fake handler marks the response as error content');
}


SKIP: {
    eval { require Plack::Test; 1 } || skip "Skipping PSGI error test: missing Plack::Test", 2;
    my $result=run_error_case(handler => 'psgi');
    skip $result->{'skip'}, 2 if $result->{'skip'};
    ok($result->{'status'} && $result->{'status'} >= 500, 'PSGI handler returns an error status');
    ok(body_matches_error($result->{'body'}), 'PSGI handler emits a recognisable error body');
}


SKIP: {
    my $pagi_skip=pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::Test::Client PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    skip "Skipping PAGI error test: $pagi_skip", 2
        if $pagi_skip;
    eval { require WebDyne::PAGI; require PAGI::Test::Client; 1 } || skip "Skipping PAGI error test: $@", 2;
    my $result=run_error_case(handler => 'pagi');
    skip $result->{'skip'}, 2 if $result->{'skip'};
    ok($result->{'status'} && $result->{'status'} >= 500, 'PAGI handler returns an error status');
    ok(body_matches_error($result->{'body'}), 'PAGI handler emits a recognisable error body');
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
