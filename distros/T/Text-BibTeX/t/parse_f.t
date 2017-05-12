# -*- cperl -*-
use strict;
use warnings;

use IO::Handle;
use Test::More tests => 73;

use vars qw($DEBUG);
use Cwd;

BEGIN {
    use_ok('Text::BibTeX');
    my $common = getcwd()."/t/common.pl";
    require $common;

}


# ----------------------------------------------------------------------
# entry creation and parsing from files

my ($fh, $entry);

my $regular_file = 'btparse/tests/data/regular.bib';

# first, from a regular ol' Perl filehandle, with 'new' and 'parse"
# bundled into one call
open (BIB, $regular_file) || die "couldn't open $regular_file: $!\n";

err_like sub { ok($entry = Text::BibTeX::Entry->new($regular_file, \*BIB)); },
  qr!$regular_file, line 5, warning: undefined macro "junk"!;

test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random', 'Foo Bar \& Sons', '1922']);
ok(!Text::BibTeX::Entry->new($regular_file, \*BIB));


# An interesting note: if I forget the 'seek' here, a bug is exposed in
# btparse -- it crashes with an internal error if it hits eof twice in a
# row.  Should add a test for that bug to the official suite, once
# it's fixed of course.  ;-)

seek (BIB, 0, 0);

# now the same, separating the 'new' and 'parse' calls -- also a test
# to see if we can pass undef for filename and get no filename in the 
# error message (and suffer no other consequences!)
err_like sub { ok($entry->parse (undef, \*BIB)); },
  qr!line 5, warning: undefined macro "junk"!;

test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random', 'Foo Bar \& Sons', '1922']);
ok(! $entry->parse (undef, \*BIB));

close (BIB);

# this is so I can stop checking the damned 'undefined macro' warning
# -- guess I really do need a "set macro value" interface at some level...
# (problem is that there's just one macro table for the whole process)

ok($entry->parse_s ('@string(junk={, III})'));
test_entry ($entry, 'string', undef, ['junk'], [', III']);

# Now open that same file using IO::File, and pass in the resulting object
# instead of a glob ref; everything else here is just the same

$fh = IO::File->new($regular_file)
   or die "couldn't open $regular_file: $!\n";
no_err sub { ok($entry = Text::BibTeX::Entry->new($regular_file, $fh)); };

test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random, III', 'Foo Bar \& Sons', '1922']);
ok(!  Text::BibTeX::Entry->new( $regular_file, $fh));
$fh->seek (0, 0);

# and again, with unbundled 'parse' call
no_err sub { ok($entry->parse ($regular_file, $fh)); };

test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random, III', 'Foo Bar \& Sons', '1922']);
ok(!  Text::BibTeX::Entry->new( $regular_file, $fh));

$fh->close;
