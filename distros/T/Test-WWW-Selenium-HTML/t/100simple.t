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
plan tests => 15;

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
    eval { $asc->run(path => "./t/htmltests/simple.html"); };
    my $error = $@;
    diag $error if $error;
    $sel = undef;
    $asc = undef;

    my $ua = LWP::UserAgent->new();
    $ua->get("http://localhost:$port/shutdown.html");

    kill 15, $pid;

    if ($error) {
        ok(0, "Failed to complete tests");
    }
}

1;
