use Test::More tests => 1;

use WikiText::Sample;

$wikitext = <<'...';
=one
=two
=three
...

eval {
    WikiText::Sample->new($wikitext)->to_html();
};

unlike $@, qr/three/;
