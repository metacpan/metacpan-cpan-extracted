#!/usr/bin/perl
BEGIN{unshift @INC, "./blib/lib"}

use Tk;
use Tk::MARC::Editor;

use MARC::File::USMARC;
my $file = MARC::File::USMARC->in( "pl/tcfm.mrc" );
my $marc = $file->next();
$file->close();
undef $file;

my $mw = MainWindow->new;
$mw->title("Testing a free-form MARC editor");

my $FRAME = $mw->Frame()->pack(-side => 'top');

#my $ed = $FRAME->Editor(-record => $marc, -background => 'white')->pack(-side => 'top');
my $ed = $FRAME->Scrolled('Editor', 
			  -scrollbars => 'e', 
			  -record => $marc, 
			  -background => 'white',
			  )->pack(-side => 'top');
my $ln = $FRAME->Text(-background => 'lightgray', -height => 10)->pack(-side => 'top');
my $b1 = $mw->Button( -text => "Dump MARC", 
		      -command => sub { my $marc = $ed->Contents();
					print $marc->as_usmarc();
				    }
		      )->pack(-side => 'left');
my $b2 = $mw->Button( -text => "Lint", 
		      -command => sub { my $s = $ed->Lint();
					$ln->Contents( $s );
				    }
		      )->pack(-side => 'left');
my $b3 = $mw->Button( -text => "Errorchecks", 
		      -command => sub { my $s = $ed->Errorchecks();
					$ln->Contents( $s );
				    }
		      )->pack(-side => 'left');
my $b4 = $mw->Button( -text => "Dump MARC and reload", 
		      -command => sub { my $marc = $ed->Contents();
					$ed->Contents( $marc );
				    }
		      )->pack(-side => 'left');

MainLoop;
