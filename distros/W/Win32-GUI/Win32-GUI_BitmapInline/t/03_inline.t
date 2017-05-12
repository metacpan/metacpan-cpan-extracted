#!perl -w
# Win32::GUI::BitmapInline test suite
# $Id: 03_inline.t,v 1.1 2008/01/13 11:42:57 robertemay Exp $
#
# - check the inline function works

use strict;
use warnings;
use IO::File();

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 17;

# Check that 'inline' is exported by default
require Win32::GUI::BitmapInline;
ok(!__PACKAGE__->can('inline'), "No 'inline' before import called");

Win32::GUI::BitmapInline->import();
can_ok(__PACKAGE__, 'inline');

# Check what inline's output looks like

# XXX I expect that using scalar reference as filename in open is not 5.6
# compatible
{ # Bitmap inlining
    my $fh = IO::File->new_tmpfile() or die "Open failed";
    my $old_fh = select $fh;

    inline('t/test.bmp');

    select $old_fh;

    $fh->seek(0,0) or die "Failed to seek back to start of file";
    
    my $buffer = do { local $/; <$fh> }; # slurp
    
    $fh->close();

    ok(length($buffer), "'inline' generates output");

    like($buffer, qr/^\$Bitmap\d+\s*=/m, 'Output starts with "$BitmapX ="');
    like($buffer, qr/^\$Bitmap1/, 'Counter starts at 1');
    like($buffer, qr/.*=\s*Win32::GUI::BitmapInline->new\s*\(\s*q\s*\(/m,
            'Output continues with "Win32::GUI::BitmapInline->new( q("');
    like($buffer, qr/\)\s*\)\s*;\s*$/m, 'Output end with ") );"');
}

{ # Icon inlining
    my $fh = IO::File->new_tmpfile() or die "Open failed";
    my $old_fh = select $fh;

    inline('t/test.ico');

    select $old_fh;

    $fh->seek(0,0) or die "Failed to seek back to start of file";
    
    my $buffer = do { local $/; <$fh> }; # slurp
    
    $fh->close();

    ok(length($buffer), "'inline' generates output");

    like($buffer, qr/^\$Icon\d+\s*=/m, 'Output starts with "$IconX ="');
    like($buffer, qr/^\$Icon2/, 'Counter continues with 2');
    like($buffer, qr/.*=\s*Win32::GUI::BitmapInline->newIcon\s*\(\s*q\s*\(/m,
            'Output continues with "Win32::GUI::BitmapInlineIcon->newIcon( q("');
    like($buffer, qr/\)\s*\)\s*;\s*$/m, 'Output end with ") );"');
}

{ # Cursor inlining
    my $fh = IO::File->new_tmpfile() or die "Open failed";
    my $old_fh = select $fh;

    inline('t/test.cur');

    select $old_fh;

    $fh->seek(0,0) or die "Failed to seek back to start of file";
    
    my $buffer = do { local $/; <$fh> }; # slurp
    
    $fh->close();

    ok(length($buffer), "'inline' generates output");

    like($buffer, qr/^\$Cursor\d+\s*=/m, 'Output starts with "$CursorX ="');
    like($buffer, qr/^\$Cursor3/, 'Counter continues with 3');
    like($buffer, qr/.*=\s*Win32::GUI::BitmapInline->newCursor\s*\(\s*q\s*\(/m,
            'Output continues with "Win32::GUI::BitmapInlineIcon->newCursor( q("');
    like($buffer, qr/\)\s*\)\s*;\s*$/m, 'Output end with ") );"');
}
