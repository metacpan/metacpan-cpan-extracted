#!/usr/bin/env perl
use Test::More;
use Test::WebDriver;

my ($host, $port) = Test::WebDriver->server_is_running;
unless ($host and $port) {
    plan skip_all => "No Webdriver server found!";
    exit 0;
}

# Try to find 
my $t = Test::WebDriver->new(
    remote_server_addr => $host, port => $port,
);
$t->get_ok('http://www.google.com');
$t->title_like(qr/Google/);
$t->body_like(qr/Google/);

done_testing();
