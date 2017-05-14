#!/usr/local/bin/perl

# Test1

use strict;
use Tk;

my $mw=MainWindow->new(-title=>'Perl Tk example');
my $w_Frame_001 = $mw -> Frame ( -borderwidth,2,-relief,'raised' ) -> pack(-anchor,'nw',-fill,'x');
my $w_Frame_020 = $mw -> Frame ( -relief,'flat' ) -> pack(-anchor,'nw',-fill,'both',-expand,1);
my $w_Listbox_018 = $w_Frame_020 -> Listbox ( -width,9 ) -> pack(-anchor,'nw',-side,'left',-fill,'y');
my $w_Frame_019 = $w_Frame_020 -> Frame ( -borderwidth,2,-relief,'sunken',-label,'w_Frame_019' ) -> pack(-anchor,'nw',-side,'left',-fill,'both',-expand,1);
my $w_Menubutton_004 = $w_Frame_001 -> Menubutton ( -text,'File',-justify,'left',-relief,'flat' ) -> pack(-anchor,'nw',-side,'left');
my $w_Menubutton_013 = $w_Frame_001 -> Menubutton ( -text,'Edit',-justify,'left',-relief,'flat' ) -> pack(-anchor,'nw',-side,'left');
my $w_Menu_014 = $w_Menubutton_013 -> Menu ( -tearoff,0,-relief,'raised' ); $w_Menubutton_013->configure(-menu=>$w_Menu_014);
my $w_command_015 = $w_Menu_014 -> command ( -accelerator,'w_command_015',-label,'w_command_015' );
my $w_checkbutton_016 = $w_Menu_014 -> checkbutton ( -accelerator,'w_checkbutton_016',-label,'w_checkbutton_016' );
my $w_Menu_005 = $w_Menubutton_004 -> Menu ( -tearoff,0,-relief,'raised' ); $w_Menubutton_004->configure(-menu=>$w_Menu_005);
my $w_command_004 = $w_Menu_005 -> command ( -accelerator,'w_command_004',-label,'w_command_004' );
my $w_command_005 = $w_Menu_005 -> command ( -accelerator,'w_command_005',-label,'w_command_005' );
my $w_cascade_023 = $w_Menu_005 -> cascade ( -accelerator,'w_cascade_023',-label,'w_cascade_023' );
my $w_separator_009 = $w_Menu_005 -> separator (  );
my $w_cascade_010 = $w_Menu_005 -> cascade ( -accelerator,'w_cascade_010',-label,'w_cascade_010' );
my $w_Menu_011 = $w_Menu_005 -> Menu ( -tearoff,0,-relief,'raised' ); $w_cascade_010->configure(-menu=>$w_Menu_011);
my $w_checkbutton_130 = $w_Menu_011 -> checkbutton ( -accelerator,'w_checkbutton_130',-label,'w_checkbutton_130' );
my $w_Menu_024 = $w_Menu_005 -> Menu ( -tearoff,0,-relief,'raised' ); $w_cascade_023->configure(-menu=>$w_Menu_024);
my $w_command_008 = $w_Menu_024 -> command ( -accelerator,'w_command_008',-label,'w_command_008' );
MainLoop;
