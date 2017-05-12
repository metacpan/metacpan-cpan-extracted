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
plan tests => 30;

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
    ok($asc->diag_body_text_on_failure(),
        'Body text is displayed on failure by default');
    $asc->diag_body_text_on_failure(0);
    ok((not $asc->diag_body_text_on_failure()),
        'Body text display disabled');
    my $mydata;
    my $myerr;
    my $out_fh = $asc->{'test_builder'}->output();
    my $err_fh = $asc->{'test_builder'}->failure_output();
    $asc->{'test_builder'}->output(\$mydata);
    $asc->{'test_builder'}->failure_output(\$myerr);
    eval { $asc->run(path => "./t/htmltests/failures1.html"); 
           $asc->run(path => "./t/htmltests/failures2.html"); 
           $asc->run(path => "./t/htmltests/failures3.html"); 
           $asc->run(path => "./t/htmltests/failures4.html"); 
           $asc->run(path => "./t/htmltests/failures5.html"); 
           $asc->run(path => "./t/htmltests/failures6.html"); };
    my $error = $@;
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

    like($mydata, qr/not ok 4 - verify_element_present 'id=div2'/,
        'verifyElementPresent failed (1)'); 
    like($mydata, qr/not ok 5 - assert_element_present 'id=div2'/,
        'assertElementPresent failed (2)');
    like($mydata, qr/not ok 7 - verify_attribute 'id=div\@style' matches 'asdf'/,
        'verifyAttribute failed (3)');
    like($mydata, qr/not ok 8 - assert_attribute 'id=div\@style' matches 'asdf'/,
        'assertAttribute failed (4)');
    like($mydata, qr/not ok 10 - verify_attribute 'id=div\@style' matches 'regexp:.\*asdf'/,
        'verifyAttribute failed (5)');
    like($mydata, qr/not ok 11 - assert_attribute 'id=div\@style' matches 'regexp:.\*asdf'/,
        'assertAttribute failed (6)');
    like($mydata, qr/not ok 13 - verify_attribute 'id=div\@style' matches 'glob:\*asdf'/,
        'verifyAttribute failed (7)');
    like($mydata, qr/not ok 14 - assert_attribute 'id=div\@style' matches 'glob:.\*asdf'/,
        'assertAttribute failed (8)');
    like($mydata, qr/not ok 16 - verify_attribute 'id=div\@style' equals 'exact:\*asdf'/,
        'verifyAttribute failed (9)');
    like($mydata, qr/not ok 17 - assert_attribute 'id=div\@style' equals 'exact:.\*asdf'/,
        'assertAttribute failed (10)');
    like($mydata, qr/not ok 19 - click\(id=div22/,
        'click failed (11)');

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
