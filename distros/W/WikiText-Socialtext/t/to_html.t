use strict;
use warnings;
use Test::More tests => 1;
use diagnostics;

use WikiText::Socialtext;

my $wikitext = <<'...';
^ Hello

Cruel, öh so
Cruel
World.
...

my $html = <<'...';
<h1>Hello</h1>
<p>Cruel, öh so<br>
Cruel<br>
World.</p>
...

my $output = WikiText::Socialtext->new($wikitext)->to_html;

is $output, $html, 'to_html works';
