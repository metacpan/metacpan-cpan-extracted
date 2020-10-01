use strict;
use warnings;
use utf8;

use Test::More;
use lib 'lib';
use FindBin qw($Bin $RealBin);
use lib "$Bin/../../Gtk3-WebKit2/lib";
use URI;

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

$webkit->open("$Bin/test/load.html");
ok(1, 'opened');
my $first_open = $webkit->get_html_source();
$webkit->refresh;
my $second_open = $webkit->get_html_source();
is ($first_open, $second_open, 'Page refreshed correctly');

$webkit->open("$Bin/test/type.html");
$webkit->go_back;

$webkit->open("file://$Bin/test/type.html");
$webkit->submit('css=form');
is($webkit->view->get_uri, "file://$Bin/test/type.html?foo=foo");
is($webkit->run_javascript('return window.location.href'), "file://$Bin/test/type.html?foo=foo");

done_testing;
