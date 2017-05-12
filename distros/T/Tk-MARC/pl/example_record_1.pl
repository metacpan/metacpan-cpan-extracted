#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC::Record;
use MARC::Record;

my $mw = MainWindow->new;
$mw->title("Editor Test");

my $record = MARC::Record->new;
my $field = MARC::Field->new('100','','','a' => 'Christensen, David A.');
$record->append_fields($field);
my $field = MARC::Field->new('245','','','a' => 'Testing the MARC Editor');
$record->append_fields($field);

$mw->MARC_Record(-record => $record)->pack;

MainLoop;
