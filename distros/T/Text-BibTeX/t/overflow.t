# -*- cperl -*-
use strict;
use warnings;

use Capture::Tiny 'capture';
use IO::Handle;
use Test::More tests => 3;

use vars qw($DEBUG);
BEGIN {
    use_ok('Text::BibTeX');
    require "t/common.pl";
}

$DEBUG = 0;


# ----------------------------------------------------------------------
# entry creation and parsing from a Text::BibTeX::File object

my ($bibfile, $entry);
my $multiple_file = 't/data/overflow.bib';

ok($bibfile =  Text::BibTeX::File->new( $multiple_file));
# this used to trigger a buffer overflow error on some machines
err_like sub { $entry =  Text::BibTeX::Entry->new( $bibfile) },
  qr!syntax error: at end of input, expected one of:!;

