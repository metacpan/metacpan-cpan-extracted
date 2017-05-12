use strict;
use warnings;
use Test::More tests => 5;

use Text::EmacsColor;

diag `emacs --version`; # for the CPAN testers

my $colorer = Text::EmacsColor->new;
ok $colorer;

my $html = $colorer->format(
    '(in-package #:foo) (define-some-random-thing :like-this)',
    'lisp',
);

isa_ok $html, 'Text::EmacsColor::Result';
like $html, qr/<span class="builtin">:foo/;

# bug 'my $str = "Hello\n";' is converted to 'my $str = "Hellon";'
$html = $colorer->format(
    'my $str = "Hello\n"',
    'cperl',
);

isa_ok $html, 'Text::EmacsColor::Result';
like $html, qr/<span class="string">"Hello\\n"/;
