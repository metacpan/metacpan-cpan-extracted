#!/usr/bin/perl
# 
# marvin - a quickly hacked-together 
#          MARc Visual INteractive stream editor
#          to show how Tk::MARC::record works
#
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC;
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
   

my $file = MARC::File::USMARC->in( $infname );
my $record = $file->next();

my $mw = MainWindow->new;
my $cnt_in = 1;
my $cnt_out = 0;
$mw->title("MARVIN [IN:$cnt_in] [OUT:$cnt_out]");

my $EDIT = $mw->Frame()->pack(-side => 'top');
my $TkMARC = $EDIT->MARC_Record(-record => $record)->pack;

$mw->Button(-text => "Write", -command => sub { my $new_rec = $TkMARC->get();
						print $new_rec->as_usmarc();
						$cnt_out++;
						$record = $file->next();
						exit unless defined $record;
						$EDIT->packPropagate('off');
						$TkMARC->packForget();
						$cnt_in++;
						$mw->title("MARVIN [IN:$cnt_in] [OUT:$cnt_out]");
						$TkMARC = $EDIT->MARC_Record(-record => $record)->pack;
					  })->pack(-side => 'left');

$mw->Button(-text => "Stop", -command => sub { $mw->destroy();
					   })->pack(-side => 'right');

$mw->Button(-text => "Skip", -command => sub { $record = $file->next();
					       exit unless defined $record;
					       $EDIT->packPropagate('off');
					       $TkMARC->packForget();
					       $cnt_in++;
					       $mw->title("MARVIN [IN:$cnt_in] [OUT:$cnt_out]");
					       $TkMARC = $EDIT->MARC_Record(-record => $record)->pack;
					   })->pack(-side => 'right');

MainLoop;
