use strict;
use warnings;
use utf8;

use Test::More;
use lib 'lib';
use FindBin qw($Bin);
use lib "$Bin/../../Gtk3-WebKit2/lib";

#Running tests as root will sometimes spawn an X11 that cannot be closed automatically and leave the test hanging
plan skip_all => 'Tests run as root may hang due to X11 server not closing.' unless $>;

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

$webkit->open("$Bin/test/check.html");

subtest 'check' => sub {

    $webkit->check('//*[@name="check_me"]');

    is(
        $webkit->eval_js(q{return document.querySelector('input').checked}),
        'true',
        '.checked is true'
    );

    is(
        $webkit->resolve_locator('//input')->get_attribute('checked'),
        'checked',
        'checked attribute exists'
    );

};


subtest 'uncheck' => sub {

    $webkit->uncheck('//*[@name="check_me"]');

    is(
        $webkit->eval_js(q{return document.querySelector('input').checked}),
        'false',
        '.checked is false'
    );

    ok(
        (not $webkit->resolve_locator('//input')->get_attribute('checked')),
        'checked attribute does not exist'
    );

};

done_testing;
