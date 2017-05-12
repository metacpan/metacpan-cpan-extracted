# -*- cperl -*-
use strict;
use warnings;

use vars qw($DEBUG);
use IO::Handle;
use File::Temp qw(tempfile);

use Test::More tests => 42;
use Cwd;
BEGIN {
    use_ok('Text::BibTeX');
    use_ok('Text::BibTeX::Bib');
    my $common = getcwd()."/t/common.pl";
    require $common;
}

$DEBUG = 1;

# Basic test of the BibEntry classes (really, its base classes
# BibFormat and BibSort)

my $entries = <<'ENTRIES';
@article{homer97,
  author = {Simpson, Homer J. and Andr{\'e} de la Poobah},
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  volume = 4,
  pages = "125--130",
  year = 1997
}

@book{george98,
  author = "George Simpson",
  title = "How to Found a Big Department Store",
  year = 1998,
  month = feb
}
ENTRIES

# (Currently) we have to go through a Text::BibTeX::File object to get
# Entry objects blessed into a structured entry class, so start
# by creating the file to parse.
my ($fh, $fn) = tempfile("tmpXXXXX", SUFFIX => '.bib', UNLINK => 1);
print {$fh} $entries;
close $fh;

# Open it as a Text::BibTeX::File object, set the structure class (which
# controls the structured entry class of all entries parsed from that
# file), and get the structure class (so we can set options on it).
my $file = Text::BibTeX::File->new ($fn);
$file->set_structure ('Bib');
my $structure = $file->structure;

# Read the two entries
my $entry1 = Text::BibTeX::BibEntry->new( $file );
my $entry2 = Text::BibTeX::BibEntry->new( $file );

$file->close;
#unlink ($fn) || warn "couldn't delete temporary file $fn: $!\n";

# The default options of BibStructure are:
#   namestyle => 'full'
#   nameorder => 'first'
#   atitle    => 1 (true)
#   sortby    => 'name'
# Let's make sure these are respected.

my @blocks = $entry1->format;
is(scalar @blocks, 4);                # 4 blocks:
ok( defined $blocks[0] );             # author
ok( defined $blocks[1] );             # title
ok( defined $blocks[2] );             # journal
ok(!defined $blocks[3] );             # note (there is no note!)

is(ref $blocks[0], 'ARRAY');      # 1 sentence, 1 clauses (2 authors)
is(scalar  @{$blocks[0]}, 1);

is($blocks[0][0], "Homer~J. Simpson and Andr{\\'e} de~la Poobah");
is(ref $blocks[1], 'ARRAY');      # 1 sentence, 1 clause for title
is(scalar @{$blocks[1]}, 1);
is($blocks[1][0], "Territorial imperatives in modern suburbia");

is(ref $blocks[2], 'ARRAY');      # 1 sentence for journal
is(scalar @{$blocks[2]}, 1);

is(ref $blocks[2][0] , 'ARRAY');   # 3 clauses in that 1 sentence
is(scalar @{$blocks[2][0]}, 3);

is($blocks[2][0][0] , 'Journal of Suburban Studies');
is($blocks[2][0][1] , '4:125--130');
is($blocks[2][0][2] , '1997');

# Tweak options, one at a time, testing the result of each tweak
$structure->set_options (nameorder => 'last');
@blocks = $entry1->format;
is($blocks[0][0], "Simpson, Homer~J. and de~la Poobah, Andr{\\'e}");

$structure->set_options (namestyle => 'abbrev',
                         nameorder => 'first');
@blocks = $entry1->format;
is($blocks[0][0] , "H.~J. Simpson and A. de~la Poobah");

$structure->set_options (nameorder => 'last');
@blocks = $entry1->format;
is($blocks[0][0] , "Simpson, H.~J. and de~la Poobah, A.");

$structure->set_options (namestyle => 'nopunct');
@blocks = $entry1->format;
is($blocks[0][0] , "Simpson, H~J and de~la Poobah, A");

$structure->set_options (namestyle => 'nospace');
@blocks = $entry1->format;
is($blocks[0][0] , "Simpson, HJ and de~la Poobah, A");

$structure->set_options (atitle_lower => 0);
@blocks = $entry1->format;
is($blocks[1][0] , "Territorial Imperatives in Modern Suburbia");

# Now some formatting tests on the second entry (a book).  Note that the
# two entries share a structure object, so the last-set options apply
# here!

@blocks = $entry2->format;
is(scalar @blocks, 4);               # again, 4 blocks:
ok(defined $blocks[0]);              # name (authors or editors)
ok(defined $blocks[1]);              # title (and volume no.)
ok(defined $blocks[2]);              # no/series/publisher/date
ok(! defined $blocks[3]);            # note (again none)

is($blocks[0][0], "Simpson, G");

is($blocks[1][0][0], "How to Found a Big Department Store");
ok(! $blocks[1][0][1]);              # no volume number

ok(! $blocks[2][0]);                 # no number/series
ok(! $blocks[2][1][0]);              # no publisher
ok(! $blocks[2][1][1]);              # no publisher address
ok(! $blocks[2][1][2]);              # no edition

is($blocks[2][1][3], 'February 1998');        # but we do at least have a date!

# fiddle a bit more with name-generation options just to make sure
# everything's in working order
$structure->set_options (namestyle => 'full',
                         nameorder => 'first');
@blocks = $entry2->format;
is($blocks[0][0], "George Simpson");

# Now test sorting: by default, the book (G. Simpson 1998) should come
# before the article (H. J. Simpson 1997) because the default sort
# order is (name, year).
ok($entry2->sort_key lt $entry1->sort_key);

# But if we change to sort by year, the article comes first
$structure->set_options (sortby => 'year');
ok($entry1->sort_key lt $entry2->sort_key);
