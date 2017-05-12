#!/usr/bin/perl -w
BEGIN { $ENV{WXPERL_OPTIONS} = 'NO_MAC_SETFRONTPROCESS'; }
use strict;

use Wx::PdfDocument;
use Test::More tests => 6;
use Cwd;
use File::Copy;

my $utilpath = $Wx::PdfDocument::_binpath;
$utilpath =~ s/\\/\//g;
my $distpath = Cwd::realpath(__FILE__);
$distpath =~ s/\\/\//g;
$distpath =~ s/\/t\/[^\/]+$//;

my $sourcettf = qq($distpath/t/data/testfont.ttf);
my $targetttf = qq($distpath/testfont.ttf);
my $targetpdf = qq($distpath/testfont.pdf);
my $targetafm = qq($distpath/testfont.afm);

for my $file ( ( $targetttf, $targetpdf, $targetafm ) ) {
    if( -f $file ) {
        chmod(0644, $file);
        unlink $file;
    }
}

ok( !-f $targetttf, 'Target ttf file clean' );
ok( !-f $targetpdf, 'Target pdf file clean' );
ok( !-f $targetafm, 'Target afm file clean' );

File::Copy::copy($sourcettf, $targetttf);

ok( -f $targetttf, 'Target ttf file present' );

my($status, $stdout, $stderr) = Wx::PdfDocument::ShowFont(qq(-f $targetttf -o $targetpdf));

is( $status, '0', 'ShowFont exited with 0' );
ok( -f $targetpdf, 'ShowFont created PDF' );

# Local variables: #
# mode: cperl #
# End: #
