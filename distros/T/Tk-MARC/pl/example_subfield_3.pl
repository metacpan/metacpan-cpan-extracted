#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}
use Tk;
use Tk::MARC::Subfield;
use MARC::Record;

my $mw = MainWindow->new;
$mw->title("Editor Test");
my $TkSubfield = $mw->MARC_Subfield(-field => '245',
				    -label => 'a',
				    -value => 'The Case for Mars.',
				    )->pack;

$mw->Button(-text => "Get", -command => sub { my $sf = $TkSubfield->get(); 
					      print "SF [" . @$sf[0] . "] [" . @$sf[1] . "]\n";
					  })->pack(-side => 'left');

MainLoop;
