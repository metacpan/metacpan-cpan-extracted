use strict;
use warnings;

use Test::More;

use Text::AsciidocDown;

my $input = "= Title\n\nA paragraph.\n";
my $converter = Text::AsciidocDown->new(
  attributes => {
    project => 'asciidoc-down',
  },
);

my $out = $converter->convert($input, {
  attributes => {
    company => 'ACME',
  },
});

is($out, "# Title\n\nA paragraph.", 'convert applies Prompt 01 doctitle mapping');
ok(!ref($out), 'convert returns a plain string');

eval { Text::AsciidocDown->convert($input) };
like($@, qr/convert must be called on an object instance/, 'class call to convert fails fast');

done_testing;
