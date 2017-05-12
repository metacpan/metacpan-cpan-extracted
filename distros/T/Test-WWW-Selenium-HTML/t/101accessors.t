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
plan tests => 41;

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
    eval { $asc->run(path => "./t/htmltests/accessors.html"); };
    my $error = $@;
    diag $error if $error;
    
    my $vars = $asc->vars();
    my $body = $vars->{'myvar'};
    $body =~ s/\s*//g;
    is($body,             'test1test2ExampleExample1Example2'.
                          'onetwothreefour', 
                          'Got body text');
    is($vars->{'width'},  '200',        'Got element width');
    is($vars->{'height'}, '300',        'Got element height');

    eval { $asc->run(data => <<EOF) };
        <html xmlns='x'><head></head><body>
            <table>
                <tbody>
                    <tr><td>assertMyInvalidAccessor</td>
                        <td>invalid</td>
                        <td>invalid</td></tr>
                </tbody>
            </table>
        </body></html>
EOF
    ok($@, 'Died on running invalid accessor');
    like($@, qr/Invalid accessor 'MyInvalidAccessor' at line 4/,
        'Got correct error message');

    eval { $asc->run(data => <<EOF) };
        <html xmlns='x'><head></head><body>
            <table>
                <tbody>
                    <tr><td>assertMyInvalidNotAccessor</td>
                        <td>invalid</td>
                        <td>invalid</td></tr>
                </tbody>
            </table>
        </body></html>
EOF
    ok($@, 'Died on running invalid accessor');
    like($@, qr/Invalid accessor 'MyInvalidNotAccessor' at line 4/,
        'Got correct error message');

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
