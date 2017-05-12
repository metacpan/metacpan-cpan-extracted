# $Id$

use warnings;
use strict;

use Test::More;

use Test::WWW::Selenium::HTML;
use IO::Socket::INET;
use Test::WWW::Selenium;
use Time::HiRes qw(usleep);

use lib './t/lib';
use TestDaemon;

if (not TestDaemon::selenium_server_exists()) {
    plan skip_all => "Unable to test, could not find Selenium Server.";
}
plan tests => 17;

my $port = TestDaemon::get_port();

my $pid = fork();
if (not $pid) {
    close STDIN;
    close STDOUT;
    close STDERR;
    TestDaemon::start($port);
} else {
    my $sel = 
        Test::WWW::Selenium->new(
            host        => "localhost",
            port        => 4444,
            browser     => "*firefox",
            browser_url => "http://localhost:$port/"
        );
    my $asc = Test::WWW::Selenium::HTML->new($sel);
    my $mydata;
    my $myerr;
    my $out_fh = $asc->{'test_builder'}->output();
    my $err_fh = $asc->{'test_builder'}->failure_output();
    $asc->{'test_builder'}->output(\$mydata);
    $asc->{'test_builder'}->failure_output(\$myerr);
    eval { $asc->run(path => "./t/htmltests/timeouts1.html"); };
    my $error = $@;
    if ($error) {
        diag $error;
    }
    eval { $asc->run(path => "./t/htmltests/timeouts2.html"); };
    $error = $@;
    if ($error) {
        diag $error;
    }
    my @tests = $asc->{'test_builder'}->details();
    my @bad_tests;
    for (my $i = 0; $i < @tests; $i++) {
        if (not $tests[$i]->{'ok'}) {
            $tests[$i]->{'ok'} = 1;
        }
    }
    my @lines = split /\n/, $mydata;
    $mydata = join "\n", grep { /^not ok/ } @lines;
    for (@lines) {
        s/^not ok/ok/;
        print "$_\n";
    }
    $asc->{'test_builder'}->output($out_fh);
    $asc->{'test_builder'}->failure_output($err_fh);
    like($mydata, qr/not ok 5 - wait_for_not_visible 'id=toggle'.*\(timed out/,
        'waitForNotVisible timed out and failed');
    like($mydata, qr/not ok 15 - wait_for_attribute 'id=one\@id' matches 'one'.*\(timed out/,
        'waitForAttribute timed out and failed');
 
    $sel = undef;
    $asc = undef;

    my $ua = LWP::UserAgent->new();
    $ua->get('http://localhost:port/shutdown.html');

    kill 15, $pid;

    if ($error) {
        ok(0, "Failed to complete tests");
    }
}

1;
