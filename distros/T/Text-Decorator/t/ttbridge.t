# vim:ft=perl
use Test::More qw(no_plan);

use Text::Decorator;

my $decorator = new Text::Decorator ("foo & bar");
$decorator->add_filter(TTBridge => all => "upper");
$decorator->add_filter(TTBridge => html => "html");
is($decorator->format_as("html"), "FOO &amp; BAR", "HTML formatting OK");
is($decorator->format_as("text"), "FOO & BAR", "Text formatting OK");
