#*** test.pl Sun Jan 22 17:25:49 2006 ***#
# Copyright (C) 2006 by Torsten Knorr
# create-soft@tiscali.de
# All rights reserved!
#-------------------------------------------------
# exit();
#-------------------------------------------------
 use strict;
 use warnings;
 use Tk;
 use lib::Tk::Image::Cut;
#-------------------------------------------------
 my $mw = MainWindow->new();
 $mw->title("Picture-Cutter");
 $mw->geometry("+5+5");
 my $cut = $mw->Cut()->grid();
 $mw->Button(
 	-text		=> "Exit",
 	-command	=> sub { exit(); },
 	)->grid();
 for(qw/
 	ButtonSelectImage
 	LabelShape
 	bEntryShape
 	ButtonColor
 	LabelWidthOut
 	EntryWidthOut
 	LabelHeightOut
 	EntryHeightOut
 	ButtonIncrease
 	ButtonReduce
 	LabelNameOut
 	EntryNameOut
 	ButtonCut
 	/)
 	{
 	$cut->Subwidget($_)->configure(
 		-font		=> "{Times New Roman} 10 {bold}",
 		);
 	}
 for(qw/
 	bEntryShape
 	EntryWidthOut
 	EntryHeightOut
 	EntryNameOut
 	Canvas
 	/)
 	{
 	$cut->Subwidget($_)->configure(
 		-background	=> "#FFFFFF",
 		);
 	}
 for(qw/
 	bEntryShape
 	EntryWidthOut
 	EntryHeightOut
 	/)
 	{
 	$cut->Subwidget($_)->configure(
 		-width		=> 6,
 		);
 	}
 $cut->Subwidget("EntryNameOut")->configure(
 		-width		=> 40,
 		);
 $cut->Subwidget("Canvas")->configure(
 	-width		=> 1000,
 	-height		=> 800,
 	);
 MainLoop();
#-------------------------------------------------




