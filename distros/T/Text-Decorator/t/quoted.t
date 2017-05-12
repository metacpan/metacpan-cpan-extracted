# vim:ft=perl
use Test::More qw(no_plan);

use Text::Decorator;

my $text = <<EOF;

> > This is a 
> test of the

early quoting system

EOF

my $decorator = new Text::Decorator ($text);
$decorator->add_filter("Quoted");
is($decorator->format_as("html"), <<EOF, "HTML formatting OK");
<span class="quotedlevel1">
<span class="quotedlevel2"><span class="quotedlevel3">> > This is a 
</span>> test of the
</span>
early quoting system
</span>
EOF
is($decorator->format_as("text"), $text, "Round-trip OK");
