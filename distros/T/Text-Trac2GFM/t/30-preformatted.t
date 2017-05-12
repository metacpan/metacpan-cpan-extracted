use strict;
use warnings;

use Test::More tests => 3;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
This sentence contains a {{{pre-formatted phrase}}}.
EOG
$expect = <<EOE;
This sentence contains a `pre-formatted phrase`.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'in-line preformatted string');

$give = <<EOG;
This is just a sentence.
{{{
And this block.
Is pre-formatted.
}}}
EOG
$expect = <<EOE;
This is just a sentence.
```
And this block.
Is pre-formatted.
```
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'preformatted block');

$give = <<EOG;
{{{#!clojure
(defn foo []
  (str "foo"))
}}}
EOG
$expect = <<EOE;
```clojure
(defn foo []
  (str "foo"))
```
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'preformatted block with syntax highlighter');

