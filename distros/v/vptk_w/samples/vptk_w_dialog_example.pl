#!/usr/local/bin/perl

# Dialog example

use Tk;

$mw=MainWindow->new(-title=>'Perl Tk example');
$w_Frame_001 = $mw -> Frame ( -borderwidth,3,-relief,'flat',-background,'gray' ) -> pack(-ipadx,6,-ipady,6);
$w_Frame_002 = $mw -> Frame ( -borderwidth,6,-relief,'ridge' ) -> pack();
$w_Label_007 = $w_Frame_002 -> Label ( -foreground,'Black',-text,'Label006',-background,'wheat2' ) -> pack(-side,'left');
$w_Label_008 = $w_Frame_002 -> Label ( -text,'Label008' ) -> pack();
$w_Text_008 = $w_Frame_002 -> Text ( -foreground,'magenta1',-background,'White' ) -> pack(-anchor,'sw',-side,'top');
$w_Frame_003 = $mw -> Frame ( -borderwidth,7,-relief,'flat',-background,'Blue' ) -> pack(-side,'top',-ipadx,8,-ipady,8);
$w_Button_004 = $w_Frame_001 -> Button ( -text,'w_Button_004',-relief,'raised',-background,'yellow' ) -> pack(-side,'left',-padx,6);
$w_Button_011 = $w_Frame_001 -> Button ( -text,'w_Button_011',-relief,'raised' ) -> pack(-padx,6,-side,'left');
$w_Button_012 = $w_Frame_001 -> Button ( -text,'w_Button_012',-relief,'raised' ) -> pack(-side,'left',-padx,6);
$w_Button_013 = $w_Frame_001 -> Button ( -text,'w_Button_013',-relief,'raised' ) -> pack(-side,'left',-padx,6);
$w_Button_005 = $w_Frame_003 -> Button ( -foreground,'DarkGreen',-text,'Ok',-relief,'raised' ) -> pack(-padx,12,-side,'left',-expand,1);
$w_Button_009 = $w_Frame_003 -> Button ( -foreground,'Red',-text,'Cancel',-relief,'raised' ) -> pack(-side,'right',-padx,12,-fill,'x',-expand,1);
MainLoop;
