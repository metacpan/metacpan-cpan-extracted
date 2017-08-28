# -*- cperl -*-
use strict;
use warnings;
use utf8;
use IO::Handle;
use Test::More tests => 54;

use vars qw($DEBUG);
use Cwd;
BEGIN {
    use_ok('Text::BibTeX');
    my $common = getcwd()."/t/common.pl";
    require $common;
}


# ----------------------------------------------------------------------
# entry creation and parsing from a string

my ($text, $entry, @warnings, $result, $text_uck, $entry_uck);

$text = <<'TEXT';
@foo { mykey,
  f1 = {hello } # { there},
  f2 = "fancy " # "that!" # foo # 1991,
  f3 = foo
    }
TEXT

# Test with a Unicode key
$text_uck = <<'TEXT';
@foo { mykeyŠ,
  f1 = {f1val},
  f2 = {f1val}
    }
TEXT

ok($entry_uck = Text::BibTeX::Entry->new());
ok($entry_uck->parse_s($text_uck));



ok($entry = Text::BibTeX::Entry->new());

err_like
  sub { ok($entry->parse_s ($text)); },
  qr/line 3, warning: undefined macro "foo".*line 4, warning: undefined macro "foo"/s;

# First, low-level tests: make sure the data structure itself looks right
ok($entry->{'status'});
ok($entry->{'type'} eq 'foo');
ok($entry->{'key'} eq 'mykey');
ok(scalar @{$entry->{fields}} == 3);
ok($entry->{fields}[0] eq 'f1' &&
      $entry->{fields}[1] eq 'f2' &&
      $entry->{fields}[2] eq 'f3');
ok(scalar keys %{$entry->{'values'}} == 3);
ok($entry->{'values'}{f1} eq 'hello there');



# Now the same tests again, but using the object's methods
test_entry ($entry, 'foo', 'mykey',
            ['f1', 'f2', 'f3'],
            ['hello there', 'fancy that!1991', '']);

# Repeat with "bundled" form (new and parse_s in one go)

err_like
  sub { ok($entry = Text::BibTeX::Entry->new($text)); },
  qr/line 3, warning: undefined macro "foo".*line 4, warning: undefined macro "foo"/s;

# Repeat tests of entry contents
test_entry ($entry, 'foo', 'mykey',
            ['f1', 'f2', 'f3'],
            ['hello there', 'fancy that!1991', '']);

# Make sure parsing an empty string, or string with no entry in it,
# just returns false

$entry = Text::BibTeX::Entry->new();

err_like sub {
  $result = $entry->parse_s ('');
  ok(! $result);
}, qr!expected "@"!;
ok(! $result);

err_like sub {
  $result = $entry->parse_s (undef);
  $result = $entry->parse_s ('top-level junk that is not caught');
}, qr!expected "@"!;
ok(! $result);

err_like sub {
  $result = $entry->parse_s ('top-level junk that is not caught');
}, qr!expected "@"!;
ok(! $result);

$result = $entry->parse_s (undef);
ok(! $result);


# Test the "proper noun at both ends" bug (the bt_get_text() call in
# BibTeX.xs stripped off the leading and trailing braces; has since
# been changed to bt_next_value(), under the assumption that compound
# values will have been collapsed to a single simple value)

# (thanks to Reiner Schotte for reporting this bug)

$text = <<'TEXT';
@foo{key, title = "{System}- und {Signaltheorie}"}
TEXT

no_err sub { $entry = Text::BibTeX::Entry->new($text); };

ok($entry->parse_ok);
test_entry ($entry, 'foo', 'key', 
            ['title'], ['{System}- und {Signaltheorie}']);
