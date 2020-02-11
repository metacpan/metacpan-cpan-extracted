use strict;
use warnings;
use utf8;

use Test::More;
use lib 'lib';
use File::Slurper 'read_text';
use FindBin qw($Bin $RealBin);
use lib "$Bin/../../Gtk3-WebKit2/lib";
use Test::Fake::HTTPD;
use URI;

use_ok 'WWW::WebKit2';

my $webkit = WWW::WebKit2->new(xvfb => 1);
eval { $webkit->init; };
if ($@ and $@ =~ /\ACould not start Xvfb/) {
    $webkit = WWW::WebKit2->new();
    $webkit->init;
}
elsif ($@) {
    diag($@);
    fail('init webkit');
}

$webkit->open("$Bin/test/events.html");
ok(1, 'opened');

$webkit->wait_for_page_to_load(100);

ok(
    $webkit->wait_for_pending_requests(100)
);

$webkit->pause(100);
$webkit->set_timeout(10000);

ok(
    $webkit->wait_for_condition(sub {
        $webkit->is_visible('css=h1');
    }, 100)
);

$webkit->eval_js("window.scrollBy(0, 100);");
ok(
    $webkit->wait_for_condition(sub {
        $webkit->eval_js("document.documentElement.scrollTop") == 100
    }, 1000)
);

ok(
    $webkit->wait_for_element_present('//div[@id="foobarbaz"]', 1000)
);

ok(
    $webkit->wait_for_element_to_disappear('//div[@id="foobarbaz"]', 1000)
);

$webkit->wait_for_alert("hello there", 100);

$webkit->fire_event('css=input', 'focus');
$webkit->wait_for_alert("focused", 100);
$webkit->fire_event('//input', 'blur');
$webkit->wait_for_alert("blurred", 100);

my $httpd = Test::Fake::HTTPD->new;

$httpd->run(sub {
    my $req = shift;
    return [ 200, [ 'Content-Type', 'text/html' ], [ read_text("$Bin/test/events.html") ] ];
});

$webkit->enable_console_log;
$webkit->open($httpd->endpoint);
$webkit->run_javascript("window.ajax_url='" . $httpd->endpoint . "'");
$webkit->click('css=button#start_ajax');
$webkit->wait_for_condition(sub {
    $webkit->resolve_locator("css=#ajax_result")->get_inner_html eq 'Hello World';
});
is($webkit->resolve_locator("css=#ajax_result")->get_inner_html, 'Hello World', 'waited for js');

$webkit->prepare_async_page_load;
$webkit->click('css=button#start_ajax_with_reload');
$webkit->wait_for_async_page_load;
ok((not $webkit->run_javascript('window.ajax_url')), 'page has been reloaded');

is($webkit->run_javascript('document.cookie'), 'foo=bar', 'cookie set');
$webkit->clear_cookies;
is($webkit->run_javascript('document.cookie'), '', 'cookies cleared');

done_testing;
