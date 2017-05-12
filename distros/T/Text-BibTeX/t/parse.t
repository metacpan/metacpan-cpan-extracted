# -*- cperl -*-
use strict;
use warnings;

use Capture::Tiny 'capture';
use IO::Handle;
use Test::More tests => 32;

use vars qw($DEBUG);
use Cwd;
BEGIN {
    use_ok('Text::BibTeX');
    my $common = getcwd()."/t/common.pl";
    require $common;
}

$DEBUG = 0;


# ----------------------------------------------------------------------
# entry creation and parsing from a Text::BibTeX::File object

my ($bibfile, $entry);
my $multiple_file = 'btparse/tests/data/simple.bib';

ok($bibfile = Text::BibTeX::File->new( $multiple_file));
err_like sub { ok($entry =  Text::BibTeX::Entry->new( $bibfile)); },
  qr!$multiple_file, line 5, warning: undefined macro "junk"!;

test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random', 'Foo Bar \& Sons', '1922']);

ok($entry->read ($bibfile));
test_entry ($entry, 'string', undef,
            ['macro', 'foo'],
            ['macro  text ', 'blah blah   ding dong ']);


ok($entry->read ($bibfile));
ok($entry->parse_ok &&
      $entry->type eq 'comment' &&
      $entry->metatype == BTE_COMMENT &&
      $entry->value eq 'this is a comment entry, anything at all can go in it (as long as parentheses are balanced), even {braces}');

ok($entry->read ($bibfile));
ok($entry->parse_ok && 
      $entry->type eq 'preamble' &&
      $entry->metatype == BTE_PREAMBLE &&
      $entry->value eq 'This is a preamble---the concatenation of several strings');

ok(! $entry->read ($bibfile));
