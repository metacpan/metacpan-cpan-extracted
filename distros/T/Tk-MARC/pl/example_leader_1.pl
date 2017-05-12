#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC::Leader;
use MARC::Record;
use MARC::File::USMARC;

my $file = MARC::File::USMARC->in( 'pl/tcfm.mrc' );
print $MARC::File::ERROR . $/ unless defined $file;

my $rec = $file->next();
$file->close();
undef $file;

my $mw = MainWindow->new;
$mw->title("leader Test");

my $TkLeader = $mw->MARC_Leader(-record => $rec,
				)->pack(-anchor => 'w');

$mw->Button(-text => "Get", -command => sub { my $ldr = $TkLeader->get();
					      print $ldr . $/;
					  })->pack(-side => 'left');

MainLoop;
