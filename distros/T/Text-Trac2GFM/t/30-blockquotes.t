use strict;
use warnings;

use Test::More tests => 3;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
This is just a line of text.

    Followed by a blockquote.

And a third paragraph, not quoted.
EOG
$expect = <<EOE;
This is just a line of text.

> Followed by a blockquote.

And a third paragraph, not quoted.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'basic blockquote');

$give = <<EOG;
This is just a line of text.

    Followed by a blockquote.
    A multi-line blockquote!
    Multi-multi-lines, even.

And a third paragraph, not quoted.
EOG
$expect = <<EOE;
This is just a line of text.

> Followed by a blockquote.
> A multi-line blockquote!
> Multi-multi-lines, even.

And a third paragraph, not quoted.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'multi-line blockquote');

$give = <<EOG;
This is just a line of text.

    Followed by a blockquote.

And a third paragraph, not quoted.

    And a second blockquote.
EOG
$expect = <<EOE;
This is just a line of text.

> Followed by a blockquote.

And a third paragraph, not quoted.

> And a second blockquote.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'multiple blockquotes');

