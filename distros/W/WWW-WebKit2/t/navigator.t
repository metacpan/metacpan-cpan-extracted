use strict;
use warnings;
use utf8;

use Test::More;
use lib 'lib';
use FindBin qw($Bin $RealBin);
use lib "$Bin/../../Gtk3-WebKit2/lib";
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
is($webkit->run_javascript('window.location.href'), "file://$Bin/test/type.html?foo=foo");

done_testing;
