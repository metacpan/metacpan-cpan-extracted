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

print "BEFORE\n-----------------------------------------------------------------\n";
print $record->as_formatted() . $/;
print "-----------------------------------------------------------------\n";

my $TkMARC = $mw->MARC_Record(-record => $record)->pack;

$mw->Button(-text => "Get", -command => sub { my $new_rec = $TkMARC->get();
					      print "AFTER\n-----------------------------------------------------------------\n";
					      print $new_rec->as_formatted() . $/;
					      print "-----------------------------------------------------------------\n";
					  })->pack(-side => 'left');
MainLoop;
