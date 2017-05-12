#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC::Indicators;
use MARC::Record;
use MARC::File::USMARC;

my $file = MARC::File::USMARC->in( 'pl/tcfm.mrc' );
print $MARC::File::ERROR . $/ unless defined $file;

my $rec = $file->next();
$file->close();
undef $file;

my $mw = MainWindow->new;
$mw->title("Editor Test");

my $fld = $rec->field('245');
$mw->MARC_Indicators(-field => '245',
		     -ind1 => $fld->indicator(1),
		     -ind2 => $fld->indicator(2),
		   )->pack(-anchor => 'w');

MainLoop;
