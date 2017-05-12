#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC::Field;
use MARC::Record;
#use MARC::Editor;

my $mw = MainWindow->new;
$mw->title("Editor Test");
my $record = MARC::Record->new;

my $field = MARC::Field->new('245','','',
			     'a' => 'The Case for Mars: ',
			     'b' => 'The plan to settle the red planet, and why we must.'
			     );
$record->append_fields($field);
my $TkFld = $mw->MARC_Field(-field => $field)->pack(-anchor => 'w');

$mw->Button(-text => "Get", -command => sub { my $fld = $TkFld->get(); 
					      if (defined $fld) {
						  print $fld->as_formatted() . $/;
					      } else {
						  print "No fields, so no record is possible.\n";
					      }
					  })->pack(-side => 'left');

MainLoop;

