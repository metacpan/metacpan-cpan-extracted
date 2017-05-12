#!/usr/bin/perl

use MARC::Batch;
use MARC::File;
use MARC::File::USMARC;
use MARC::Record;
use Tk;
#use Tk::FBox;
use Tk::MARC::Editor;

use Data::Dumper;

my $cnt = 1;
my $batch;
my $marc;
my $filename;

my $mw = MainWindow->new;
$mw->geometry( "800x600+0+0" );
$mw->title("Sample Tk::MARC::Editor application");

my $Instructions = SetInstructions();

my $ed;

my $menubar =  $mw->Menu();
$mw->configure(-menu => $menubar);
my $filemenu = $menubar->Menubutton(-text => 'File');
$filemenu->command( -label  => 'Open',
		    -command => \&OpenFile 
		    );
$filemenu->command( -label  => 'Count',
		    -command => \&CountRecs 
		    );
$filemenu->separator();
$filemenu->command(-label => 'Exit', -command => sub {exit;} );
my $recordmenu = $menubar->Menubutton(-text => 'Record');
$recordmenu->command( -label => 'Lint',
		      -command => \&Lint
		      );
$recordmenu->command( -label => 'Errorchecks',
		      -command => \&Errorchecks
		      );
my $colormenu = $menubar->Menubutton(-text => 'Colors');
$colormenu->command( -label => 'Load color scheme',
		     -command => \&LoadColorScheme,
		     );
$colormenu->command( -label => 'Save color scheme',
		     -command => \&SaveColorScheme,
		     );
$colormenu->separator();
$colormenu->command( -label => 'Background',
		     -command => sub { $ed->configure(-background => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Field label foreground',
		     -command => sub { $ed->configure(-fieldfg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Field label background',
		     -command => sub { $ed->configure(-fieldbg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Indicator 1 foreground',
		     -command => sub { $ed->configure(-ind1fg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Indicator 1 background',
		     -command => sub { $ed->configure(-ind1bg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Indicator 2 foreground',
		     -command => sub { $ed->configure(-ind2fg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Indicator 2 background',
		     -command => sub { $ed->configure(-ind2bg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Subfield foreground',
		     -command => sub { $ed->configure(-subfieldfg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Subfield background',
		     -command => sub { $ed->configure(-subfieldbg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Data foreground',
		     -command => sub { $ed->configure(-datafg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Data background',
		     -command => sub { $ed->configure(-databg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Fixed-fields foreground',
		     -command => sub { $ed->configure(-fixedfg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Fixed-fields background',
		     -command => sub { $ed->configure(-fixedbg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Leader foreground',
		     -command => sub { $ed->configure(-leaderfg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Leader background',
		     -command => sub { $ed->configure(-leaderbg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Leader editable areas foreground',
		     -command => sub { $ed->configure(-leadereditfg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );
$colormenu->command( -label => 'Leader editable areas background',
		     -command => sub { $ed->configure(-leadereditbg => $ed->chooseColor(-initialcolor => 'gray')); }
		     );

my $FRAME = $mw->Frame(-width => 800, -height => 600)->pack(-side => 'top', -expand => 1, -fill => 'x');
my $FRAME_Instructions  = $FRAME->Frame(-height => 50)->pack(-side => 'top');
my $FRAME_Display       = $FRAME->Frame(-height => 300)->pack(-side => 'top');
my $FRAME_Actions       = $FRAME->Frame(-height => 50)->pack(-side => 'top');
my $FRAME_Messages      = $FRAME->Frame(-height => 150)->pack(-side => 'top');

$FRAME_Instructions->Label(-textvariable => \$Instructions,
			   )->pack(-side => 'top');
$FRAME_Display->Label(-textvariable => \$filename,
		      )->pack(-side => 'top');
$FRAME_Display->Label(-textvariable => \$cnt,
		      )->pack(-side => 'top');

my $msgs = $FRAME_Messages->Scrolled("Text", 
				     -scrollbars => 'e', 
				     -background => 'lightgray',
				     -height => 10,
				     )->pack(-side => 'top');

my $b1 = $FRAME_Actions->Button(-text => "Next record",
				-activebackground => 'white',
				-command => sub {
				    if ($marc = $batch->next() ) {
					$ed->Contents($marc);
					$msgs->Contents( $ed->Lint() );
					$cnt++;
				    } else {
					$msgs->Contents("This is the last record\n");
					$msgs->insert('end',"(or there may have been a problem reading the file...\n");
					$msgs->insert('end',"...you can do File | Count to see how many records there *should* be)\n");
				    }
				},
				-state => 'disabled',
				)->pack(-side => 'left');

my $b2 = $FRAME_Actions->Button(-text => "Write record to STDOUT",
				-activebackground => 'white',
				-command => sub {
				    my $marc = $ed->Contents();
				    print $marc->as_usmarc();
				},
				-state => 'disabled',
				)->pack(-side => 'left');

my $b3 = $FRAME_Actions->Button(-text => "Write lint to STDERR",
				-activebackground => 'white',
				-command => sub {
				    my $s = $ed->Lint();
				    print STDERR "$s\n";
				},
				-state => 'disabled',
				)->pack(-side => 'left');

my $b4 = $FRAME_Actions->Button(-text => "Write errorcheck to STDERR",
				-activebackground => 'white',
				-command => sub {
				    my $s = $ed->Errorchecks();
				    print STDERR "$s\n";
				},
				-state => 'disabled',
				)->pack(-side => 'left');
my $b5 = $FRAME_Actions->Button(-text => "Oops! Reload original",
				-activebackground => 'white',
				-command => sub {
				    $ed->Contents( $marc );
				},
				-state => 'disabled',
				)->pack(-side => 'left');


MainLoop;

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
sub SetInstructions {
    return <<EOT;

Use the File menu to select a file of MARC records.
Step through the file one record at a time by clicking the [Next] button.
Use the Record menu to Lint or Errorcheck the record.
You can right-click on the record you are editing to bring up a menu for adding fields/subfields.
EOT

}

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
sub OpenFile {
#    $filename = $mw->FBox()->Show;
    $filename = $mw->getOpenFile(-title=> "Open MARC File",
				 -filetypes => [['MARC Files','.mrc'],['All Files','*.*']]
				 );

    chomp $filename;
    if ($filename) {
	$batch = MARC::Batch->new( 'USMARC', $filename );
	$batch->strict_off();
	$batch->warnings_off();
	$marc = $batch->next();

	if ($ed) {
	    $ed->Contents( $marc );
	} else {
	    $ed = $FRAME_Display->Scrolled('Editor', 
					   -scrollbars => 'e', 
					   -record => $marc, 
					   -background => 'white',
					   )->pack(-side => 'top');
	}

	$msgs->Contents( $ed->Lint() );
	$cnt = 1;
	$b1->configure(-state => 'normal');
	$b2->configure(-state => 'normal');
	$b3->configure(-state => 'normal');
	$b4->configure(-state => 'normal');
	$b5->configure(-state => 'normal');
    } else {
	exit 0;
    }
}

sub CountRecs {
    if ($filename) {
	$msgs->Contents("Counting records....\n");
	#$mw->configure(-cursor=> 'watch');
	$mw->Busy(-recurse => 1);
	my $file = MARC::File::USMARC->in( $filename );
	$iCount = 0;
	while ( my $marc = $file->skip() ) {
	    $iCount++;
	}
	
	#$mw->configure(-cursor => 'top_left_arrow'); 
	$mw->Unbusy();
	$msgs->insert('end',"$filename has:\n");
	$msgs->insert('end',"$iCount records\n");
    } else {
	$msgs->insert('end',"You must open a file first!\n");
    }
}

sub LoadColorScheme {
#    my $filename = $mw->FBox()->Show;
    my $filename = $mw->getOpenFile(-title=> "Open Tk::MARC::Editor color-scheme file",
				    -filetypes => [['Tk::MARC::Editor Color-scheme Files','.cs'],['All Files','*.*']]
				    );
    if ($filename) {
	my %color = ();
	open CS, "<$filename";
	while (<CS>) {
	    chomp;
	    my $value = $_;
	    $value =~ s/^\w+\s+(\#?\w+).*$/$1/;
	    for ($_) {
		/^leaderfg\s/     and do { $color{leader}{fg} = $value; last; };
		/^leaderbg\s/     and do { $color{leader}{bg} = $value; last; };
		/^leadereditfg\s/ and do { $color{leaderedit}{fg} = $value; last; };
		/^leadereditbg\s/ and do { $color{leaderedit}{bg} = $value; last; };
		/^fieldfg\s/      and do { $color{field}{fg} = $value; last; };
		/^fieldbg\s/      and do { $color{field}{bg} = $value; last; };
		/^ind1fg\s/       and do { $color{ind1}{fg} = $value; last; };
		/^ind1bg\s/       and do { $color{ind1}{bg} = $value; last; };
		/^ind2fg\s/       and do { $color{ind2}{fg} = $value; last; };
		/^ind2bg\s/       and do { $color{ind2}{bg} = $value; last; };
		/^subfieldfg\s/   and do { $color{subfield}{fg} = $value; last; };
		/^subfieldbg\s/   and do { $color{subfield}{bg} = $value; last; };
		/^datafg\s/       and do { $color{data}{fg} = $value; last; };
		/^databg\s/       and do { $color{data}{bg} = $value; last; };
		/^fixedfg\s/      and do { $color{fixed}{fg} = $value; last; };
		/^fixedbg\s/      and do { $color{fixed}{bg} = $value; last; };
		/^background\s/   and do { $color{background} = $value; last; };
	    }
	}
	close CS;
	$ed->ColorScheme(\%color);
    }
}

sub SaveColorScheme {
#    my $filename = $mw->FBox(-type => 'save')->Show;
    my $filename = $mw->getSaveFile(-title=> "Save Tk::MARC::Editor color-scheme file",
				    -filetypes => [['Tk::MARC::Editor Color-scheme Files','.cs'],['All Files','*.*']],
				    -defaultextension => ".cs",
				    );
    if ($filename) {
	my $href = $ed->ColorScheme();
	open CS, ">$filename";
	foreach $key (sort keys %{ $href }) {
	    print CS "$key" . "fg\t" . $href->{$key}{fg} . "\n" if ($href->{$key}{fg});
	    print CS "$key" . "bg\t" . $href->{$key}{bg} . "\n" if ($href->{$key}{bg});
	}
	print CS "background\t" . $href->{background} . "\n" if ($href->{background});
	close CS;
    }
}


sub Lint { 
    $msgs->Contents( $ed->Lint() ) if $ed;
}

sub Errorchecks { 
    $msgs->Contents( $ed->Errorchecks() ) if $ed;
}
		      
