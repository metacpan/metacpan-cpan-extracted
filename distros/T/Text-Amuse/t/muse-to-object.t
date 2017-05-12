#!perl

use strict;
use warnings;
use Test::More tests => 7;
use Text::Amuse::Functions qw/muse_to_object/;
my $muse =<<'MUSE';

  Signed.

                                A. Pallino
MUSE

my $doc = muse_to_object($muse);
# parse
ok $doc->document;
my $filename = $doc->file;
ok (-f $filename, "$filename exists");
ok($doc->isa('Text::Amuse'), "object properly returned");
ok($doc->as_html);
ok($doc->as_latex);
ok(scalar($doc->as_splat_html));
undef $doc;
ok(! -f $filename, "$filename is gone now");
