use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use lib "$RealBin/../lib";

use File::Basename qw(basename dirname);
use File::Spec;
use File::Temp qw(tempfile);
use HTTP::Status qw(HTTP_INTERNAL_SERVER_ERROR);
use IPC::Open3;
use Symbol qw(gensym);


my $source_fn=File::Spec->catfile(dirname($RealBin), 't.error', 'error_basic.psp');
open(my $source_fh, '<', $source_fn) || die "unable to open '$source_fn', $!";
my $source_text=do {
    local $/;
    <$source_fh>;
};
close($source_fh) || die "unable to close '$source_fn', $!";

my ($fixture_fh, $fixture_fn)=tempfile('error_format_XXXX', DIR => $RealBin, SUFFIX => '.psp', UNLINK => 1);
print {$fixture_fh} $source_text;
close($fixture_fh) || die "unable to close '$fixture_fn', $!";
my $fixture_cn=basename($fixture_fn);


sub run_case {
    my (%arg)=@_;
    my $handler=$arg{'handler'};
    my $error_text=$arg{'error_text'};
    my $fixture_fn=$arg{'fixture_fn'};
    my $fixture_cn=$arg{'fixture_cn'};
    my $repo_dn=$arg{'repo_dn'};
    my $fixture_dn=dirname($fixture_fn);

    my %code=(
        fake => <<'END_FAKE',
use IO::String;
use HTTP::Headers::Fast;
use WebDyne;
use WebDyne::Request::Fake;
WebDyne->init();
my $body=q();
my $fh=IO::String->new($body);
my $r=WebDyne::Request::Fake->new(
    filename   => $ENV{'WEBDYNE_TEST_ERROR_FIXTURE'},
    select     => $fh,
    noheader   => 1,
    headers_in => HTTP::Headers::Fast->new(),
);
my $status=WebDyne->handler($r);
$fh->close();
my $ctype=$r->content_type() || q();
my $kind=($body =~ /^\s*<!DOCTYPE html>|^\s*<html/i) ? 'html' : 'text';
print "status=$status\nctype=$ctype\nkind=$kind\n";
END_FAKE
        psgi => <<'END_PSGI',
use WebDyne::PSGI;
use Plack::Test;
use HTTP::Request::Common qw(GET);
my $app=WebDyne::PSGI->new(root => $ENV{'WEBDYNE_TEST_ERROR_ROOT'})->to_app();
my $res=Plack::Test->create($app)->request(GET('/' . $ENV{'WEBDYNE_TEST_ERROR_CN'}));
my $body=$res->decoded_content();
my $kind=($body =~ /^\s*<!DOCTYPE html>|^\s*<html/i) ? 'html' : 'text';
print "status=".$res->code()."\n";
print "ctype=".($res->header('Content-Type') || q())."\n";
print "kind=$kind\n";
END_PSGI
        pagi => <<'END_PAGI',
use WebDyne::PAGI;
use PAGI::Test::Client;
my $app=WebDyne::PAGI->new(root => $ENV{'WEBDYNE_TEST_ERROR_ROOT'})->to_app();
my $res=PAGI::Test::Client->new(app => $app)->get('/' . $ENV{'WEBDYNE_TEST_ERROR_CN'});
my $body=$res->content();
my $kind=($body =~ /^\s*<!DOCTYPE html>|^\s*<html/i) ? 'html' : 'text';
print "status=".$res->status()."\n";
print "ctype=".($res->header('content-type') || q())."\n";
print "kind=$kind\n";
END_PAGI
    );

    my %env=(
        %ENV,
        WEBDYNE_CONF               => '.',
        WEBDYNE_ERROR_TEXT         => $error_text,
        WEBDYNE_TEST_ERROR_FIXTURE => $fixture_fn,
        WEBDYNE_TEST_ERROR_ROOT    => $fixture_dn,
        WEBDYNE_TEST_ERROR_CN      => $fixture_cn,
    );

    my $stderr=gensym();
    local %ENV=%env;
    my $pid=open3(undef, my $stdout, $stderr, $^X, '-Ilib', '-e', $code{$handler});
    my $out=do { local $/; <$stdout> };
    my $err=do { local $/; <$stderr> };
    waitpid($pid, 0);
    my $exit=$? >> 8;
    die "subprocess for $handler failed: $err" if $exit != 0;

    my %result=map {
        my ($k, $v)=split(/=/, $_, 2);
        $k => $v;
    } grep { length($_) } split(/\n/, $out);
    return \%result;
}


my @case=(
    ['fake', 1, 'text', qr{text/plain}i],
    ['fake', 0, undef,   qr{text/html}i],
    ['psgi', 1, 'text', qr{text/plain}i],
    ['psgi', 0, 'html', qr{text/html}i],
    ['pagi', 1, 'text', qr{text/plain}i],
    ['pagi', 0, 'html', qr{text/html}i],
);

for my $case (@case) {
    my ($handler, $error_text, $kind_expect, $ctype_re)=@{$case};
    SKIP: {
        skip 'Skipping PSGI format test: missing Plack::Test', 3
            if ($handler eq 'psgi' && !eval { require WebDyne::PSGI; require Plack::Test; 1 });
        skip 'Skipping PAGI format test: missing PAGI::Test::Client', 3
            if ($handler eq 'pagi' && !eval { require WebDyne::PAGI; require PAGI::Test::Client; 1 });

        my $result=run_case(
            handler    => $handler,
            error_text => $error_text,
            fixture_fn => $fixture_fn,
            fixture_cn => $fixture_cn,
            repo_dn    => dirname($RealBin),
        );

        is($result->{'status'} + 0, HTTP_INTERNAL_SERVER_ERROR, "$handler returns 500 when rendering an error");
        if (defined($kind_expect)) {
            is($result->{'kind'}, $kind_expect, "$handler respects WEBDYNE_ERROR_TEXT=$error_text for body format");
        }
        else {
            pass("$handler switches mime type for WEBDYNE_ERROR_TEXT=$error_text");
        }
        like($result->{'ctype'}, $ctype_re, "$handler emits matching content type for WEBDYNE_ERROR_TEXT=$error_text");
    }
}


done_testing();
