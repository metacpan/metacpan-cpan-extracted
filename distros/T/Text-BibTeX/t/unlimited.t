# -*- cperl -*-
use strict;
use warnings;

use Capture::Tiny 'capture';
use IO::Handle;
use Test::More tests => 4;

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
my $multiple_file = 't/unlimited.bib';

ok($bibfile = Text::BibTeX::File->new( $multiple_file));
err_like sub { ok($entry =  Text::BibTeX::Entry->new( $bibfile)) },
  qr!warning: possible runaway string started at line!;

