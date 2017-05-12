#!/usr/bin/perl
# 
# muse - a quickly hacked-together 
#        MARC un-optimized sample editor
#          to show how Tk::MARC::record works
#
# Note that this beast slurps *all* records in the file...
# so make it a small one :-)
#
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC;
use MARC::Batch;
use MARC::Record;
use MARC::File::USMARC;

my $infname;
my $outfname;
while (@ARGV) {
    for (shift @ARGV) {
	m/^-i$/     && do { $infname = shift;  };
	m/^-o$/     && do { $outfname = shift; };
	m/^-?$/     && do { print "usage: marvin.pl -i infile [-o outfile]\n"; };
    }
}

if (defined $outfname) {
    open(STDOUT,"> $outfname") or die "can't redirect STDOUT: $!";
}
   


my $mw = MainWindow->new;
$mw->title("MUSE");

my $TITLES = $mw->Frame()->pack(-side => 'left', -expand => 1, -fill => 'y');
my $BUTTONS = $mw->Frame()->pack(-side => 'bottom', -expand => 1, -fill => 'x');

my $lb = $TITLES->Scrolled("Listbox", -scrollbars => "e", -selectmode => 'single', 
			   -height => 25, -width => 30
			   )->pack();

my @records = ();
my $batch = new MARC::Batch( 'USMARC', $infname );
while ( my $marc = $batch->next ) {
    push @records, $marc;
    my $s = sprintf("[%3d] %s", $#records, $marc->title());
    $lb->insert('end', $s);
}

my $EDIT = $mw->Frame()->pack(-side => 'left');

my $TkMARC = $EDIT->MARC_Record(-record => $records[0])->pack(-side => 'top');

$BUTTONS->Button(-text => "Write", -command => sub { my $new_rec = $TkMARC->get();
						     print $new_rec->as_usmarc();
						     $EDIT->packPropagate('off');
						     $TkMARC->packForget();
						 })->pack(-side => 'left');

$BUTTONS->Button(-text => "Done", -command => sub { $mw->destroy();
						})->pack(-side => 'right');

$lb->bind('<Button-1>', sub { $EDIT->packPropagate('off');
			      $TkMARC->packForget();
			      my @selected = $lb->curselection();
			      $TkMARC = $EDIT->MARC_Record(-record => $records[ $selected[0] ] )->pack;
			  } );

MainLoop;
