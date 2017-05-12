#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC::Field;
use MARC::Record;

my $mw = MainWindow->new;
$mw->title("Editor Test");
my $record = MARC::Record->new;
my $field = MARC::Field->new('100','','','a' => 'Christensen, David A.');
$record->append_fields($field);
$mw->MARC_Field(-field => $field)->pack(-anchor => 'w');

my $field = MARC::Field->new('245','','',
			     'a' => 'The Case for Mars: ',
			     'b' => 'The plan to settle the red planet, and why we must.'
			     );
$record->append_fields($field);
$mw->MARC_Field(-field => $field)->pack(-anchor => 'w');

MainLoop;
