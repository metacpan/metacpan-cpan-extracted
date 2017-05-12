# vim:ft=perl
use Test::More qw(no_plan);

use Text::Decorator;

my $decorator = new Text::Decorator ("foo & http://www.perl.com/ bar");
$decorator->add_filter(TTBridge => html => "html");
$decorator->add_filter("URIFind");
is($decorator->format_as("html"), 
    'foo &amp; <a href="http://www.perl.com/">http://www.perl.com/</a> bar',
    "HTML formatting OK");
is($decorator->format_as("text"), "foo & http://www.perl.com/ bar", "Text formatting OK");

$decorator = new Text::Decorator(q{
    Warnock's dilemma applies.
    You can find the patch at
    <http://rt.perl.org/rt2/Ticket/Display.html?id=15923> if you're
    interested.
});
    $decorator->add_filter("URIFind");
like($decorator->format_as("html"), 
    qr/^\s+Warnock/,
    "URL not moved to beginning");
