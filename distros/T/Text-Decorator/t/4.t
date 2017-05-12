# vim:ft=perl
use Test::More qw(no_plan);

use Text::Decorator;

my $decorator = new Text::Decorator ("foo & bar");
$decorator->add_filter("Quoted");
is($decorator->format_as("html"), <<EOF, "HTML formatting OK");
<span class="quotedlevel1">foo & bar
</span>
EOF
$decorator->add_filter(TTBridge => html => "html");
is($decorator->format_as("html"), <<EOF, "HTML formatting OK");
<span class="quotedlevel1">foo &amp; bar
</span>
EOF
