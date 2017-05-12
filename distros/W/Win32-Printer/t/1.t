#------------------------------------------------------------------------------#
# Win32::Printer & Win32::Printer (NATIVE) test script                         #
# Copyright (C) 2003 Edgars Binans                                             #
#------------------------------------------------------------------------------#

use Test::Simple tests => 53;

use strict;
use warnings;

use Win32::Printer;
use Win32::Printer::Enum;
use Win32::Printer::Enum qw( Drivers Ports Monitors Processors Types Jobs );

#------------------------------------------------------------------------------#

my $dc = new Win32::Printer( file => "t/tmp/test.ps" );

ok ( defined($dc), 'new()' );

ok ( defined($dc->Debug(0)), 'Debug()' );

ok ( defined($dc->Caps(DRIVERVERSION)), 'Caps()' );
ok ( $dc->Unit('in') == 1, 'Unit()' );

ok ( defined($dc->Abort()), 'Abort()' );
ok ( $dc->Start("Test 1") == 1, 'Start()' );

ok ( defined($dc->Inject(PSI_EOF, 0, "%;)")), 'Inject()' );

ok ( defined($dc->Brush(0, 128, 0)), 'Brush()' );
ok ( $dc->Fill(ALTERNATE) == 1,  'Fill()' );
ok ( defined($dc->Pen(5, 0, 0, 255)), 'Pen()' );

ok ( $dc->Image('t/t.wmf', 0, 0, 5, 5) != 0, 'Image() wmf direct' );
ok ( $dc->Image('t/t.emf') != 0, 'Image() emf' );
ok ( $dc->Close('t/t.emf') == 1, 'Close() Image direct' );

my $fontref = $dc->Font('Arial Bold Italic Underline Strike', 20, 5);
ok ( $fontref != 0, 'Font() set');
ok ( $dc->Font($fontref) == $fontref, 'Font() select');
ok ( defined($dc->Color(128, 128, 128)), 'Color()' );

ok ( $dc->Write("This is test again!", 3, 3.5, RIGHT) != 0, 'Write() string' );
ok ( $dc->Write("... and again!", 2, 2, JUSTIFY, 5) != 0, 'Write() justify' );
ok ( $dc->Write("Test text", 1, 1, 3, 50) != 0, 'Write() draw' );
ok ( $dc->Write2("... and again!", 3, 3, 2, JUSTIFY) != 0, 'Write2()' );

ok ( $dc->Fit("Bla-bla-bla!", 12) != 0, 'Fit()' );

ok ( defined($dc->FontEnum()), 'FontEnum' );

ok ( defined($dc->FontEnum(12)), 'FontSpace' );

ok ( $dc->Space(-1, 0, 0, -1, $dc->{xsize}, $dc->{ysize}) == 1, 'Space()' );

ok ( $dc->Arc(7.5, 3.5, 3, 2, 0, 90) == 1, 'Arc()' );
ok ( $dc->ArcTo(7.5, 3.5, 3, 2, 0, 90) == 1, 'ArcTo()' );
ok ( $dc->Chord(5, 5, 3, 2, 0, 90) == 1, 'Chord()' );
ok ( $dc->Ellipse(1, 6, 3, 2) == 1, 'Ellipse()' );
ok ( $dc->Line(3, 5, 10, 7) == 1, 'Line()' );
ok ( $dc->LineTo(7, 7) == 1, 'LineTo()' );
ok ( defined($dc->Move(1, 1)), 'Move()' );
ok ( $dc->Pie(8, 3, 3, 2, 0, 90) == 1, 'Pie()' );
ok ( $dc->Bezier(0, 0, 8, 6, 3, 6, 9, 5) == 1, 'Bezier()' );
ok ( $dc->BezierTo(8, 6, 6, 6, 9, 5) == 1, 'BezierTo()' );
ok ( $dc->Poly(1, 1, 2, 2, 2, 1, 4, 8) == 1, 'Poly()' );
ok ( $dc->Rect(6, .5, 3, 2, .5) == 1, 'Rect()' );

ok ( $dc->Page() == 1, 'Page()' );

ok ( $dc->PBegin() == 1, 'PBegin()' );
$dc->Ellipse(1, 6, 6, 2);
ok ( defined($dc->PEnd()), 'PEnd()' );
ok ( $dc->PClip(CR_AND) == 1, 'PClip()' );

$dc->PBegin();
$dc->Ellipse(1, 6, 3, 2);
$dc->Ellipse(2, 6, 3, 2);
$dc->PEnd();
ok ( $dc->PDraw() == 1, 'PDraw()' );

$dc->PBegin();
ok ( $dc->PAbort() == 1, 'PAbort()' );

ok ( defined($dc->Next("Test 2")), 'Next()' );
ok ( defined($dc->End()), 'End()' );

ok ( defined($dc->FontEnum("Arial")), 'Printers()');

ok ( defined($dc->Close()), 'Close()' );

#------------------------------------------------------------------------------#

ok ( defined(Printers()), 'Printers()');
ok ( defined(Drivers()), 'Drivers()');
ok ( defined(Ports()), 'Ports()');
ok ( defined(Monitors()), 'Monitors()');
ok ( defined(Processors()), 'Processors()');
ok ( defined(Types()), 'Types()');
my @printer = Printers();
ok ( defined(Jobs($printer[0]{PrinterName}, 0, 1)), 'Jobs()');

#------------------------------------------------------------------------------#

unlink <t/tmp/*.*>;
