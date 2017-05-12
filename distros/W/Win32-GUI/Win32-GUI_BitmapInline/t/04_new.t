#!perl -w
# Win32::GUI::BitmapInline test suite
# $Id: 04_new.t,v 1.1 2008/01/13 11:42:57 robertemay Exp $
#
# - check the new function works for bitmaps

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 3;
use IO::File();

use Win32::GUI::BitmapInline();

# Check that 'inline' is not exported with empty import list
ok(!__PACKAGE__->can('inline'), "'inline' not exported");
# Check that 'new' is not exported with empty import list
ok(!__PACKAGE__->can('new'), "'new' not exported");

# use inline to create some inline data

# XXX I expect that using scalar reference as filename in open is not 5.6
# compatible
{ # Bitmap inlining
    my $fh = IO::File->new_tmpfile() or die "Open failed";
    my $old_fh = select $fh;

    Win32::GUI::BitmapInline::inline('t/test.bmp');

    select $old_fh;

    $fh->seek(0,0) or die "Failed to seek back to start of file";
    
    my $buffer = do { local $/; <$fh> };
    
    $fh->close();

    my $Bitmap1;

    eval $buffer;

    isa_ok($Bitmap1, "Win32::GUI::Bitmap", "Created a bitmap");
}
