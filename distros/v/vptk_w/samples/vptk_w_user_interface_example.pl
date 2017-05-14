#!/usr/local/bin/perl

# Self-design example

use strict;
use Tk;
use Tk::Adjuster;
use Tk::Button;
use Tk::Frame;
use Tk::Label;
use Tk::Listbox;
use Tk::Menu;
use Tk::Menubutton;

my $mw=MainWindow->new(-title=>'Perl Tk example');
my $menu_Frame = $mw -> Frame ( -borderwidth=>3, -relief=>'raised' ) -> pack(-anchor=>'nw', -side=>'top', -fill=>'x');
my $w_Menubutton_014 = $menu_Frame -> Menubutton ( -text=>'Menubutton1', -justify=>'left', -relief=>'flat' ) -> pack(-anchor=>'nw', -side=>'left');
my $w_Menu_015 = $w_Menubutton_014 -> Menu ( -relief=>'raised', -tearoff=>0 ); $w_Menubutton_014->configure(-menu=>$w_Menu_015);
my $w_command_016 = $w_Menu_015 -> command ( -command=>\&say_hello, -label=>'Say hello' );
my $w_command_017 = $w_Menu_015 -> command ( -label=>'w_command_017' );
my $w_command_018 = $w_Menu_015 -> command ( -label=>'w_command_018' );
my $w_separator_019 = $w_Menu_015 -> separator (  );
my $w_cascade_020 = $w_Menu_015 -> cascade ( -label=>'w_cascade_020' );
my $w_Menu_021 = $w_Menu_015 -> Menu ( -relief=>'raised', -tearoff=>0 ); $w_cascade_020->configure(-menu=>$w_Menu_021);
my $w_command_022 = $w_Menu_021 -> command ( -label=>'w_command_022' );
my $w_Menubutton_023 = $menu_Frame -> Menubutton ( -text=>'Menubutton2', -justify=>'left', -relief=>'flat' ) -> pack(-anchor=>'nw', -side=>'left');
my $w_Menubutton_026 = $menu_Frame -> Menubutton ( -text=>'Menubutton9', -justify=>'left', -relief=>'flat' ) -> pack(-anchor=>'ne', -side=>'right');
my $w_Menu_027 = $w_Menubutton_026 -> Menu ( -relief=>'raised', -tearoff=>0 ); $w_Menubutton_026->configure(-menu=>$w_Menu_027);
my $w_command_028 = $w_Menu_027 -> command ( -label=>'w_command_028' );
my $w_command_029 = $w_Menu_027 -> command ( -label=>'w_command_029' );
my $w_Menu_024 = $w_Menubutton_023 -> Menu ( -relief=>'raised', -tearoff=>0 ); $w_Menubutton_023->configure(-menu=>$w_Menu_024);
my $w_command_025 = $w_Menu_024 -> command ( -label=>'w_command_025' );
my $w_command_030 = $w_Menu_024 -> command ( -label=>'w_command_030' );
my $Button_Frame = $mw -> Frame ( -relief=>'raised' ) -> pack(-anchor=>'nw', -side=>'top', -fill=>'x', -ipady=>2);
my $Tree_Frame = $mw -> Frame ( -relief=>'flat' ) -> pack(-anchor=>'nw', -side=>'top', -fill=>'both', -expand=>1);
my $w_Listbox_022 = $Tree_Frame -> Listbox (  ) -> pack(-anchor=>'nw', -side=>'left', -fill=>'y');
my $w_packAdjust_031 = $w_Listbox_022 -> packAdjust ( -side=>'left' );
my $w_Frame_023 = $Tree_Frame -> Frame ( -borderwidth=>2, -relief=>'sunken', -label=>'w_Frame_023' ) -> pack(-anchor=>'nw', -side=>'left', -fill=>'both', -expand=>1);
my $Status_Frame = $mw -> Frame ( -relief=>'raised' ) -> pack(-anchor=>'s', -side=>'bottom', -fill=>'x');
my $w_Label_020 = $Status_Frame -> Label ( -text=>'w_Label_020', -borderwidth=>2, -relief=>'sunken' ) -> pack(-anchor=>'nw', -side=>'left');
my $w_Label_021 = $Status_Frame -> Label ( -text=>'w_Label_021', -borderwidth=>2, -relief=>'sunken' ) -> pack(-anchor=>'ne', -side=>'right');
my $w_Button_007 = $Button_Frame -> Button ( -text=>'| |', -relief=>'raised' ) -> pack(-anchor=>'w', -side=>'left', -padx=>2);
my $w_Button_008 = $Button_Frame -> Button ( -text=>'|/|', -relief=>'raised' ) -> pack(-anchor=>'w', -side=>'left', -padx=>2);
my $w_Button_009 = $Button_Frame -> Button ( -text=>'|%|', -relief=>'raised' ) -> pack(-anchor=>'w', -side=>'left', -padx=>2);
my $w_Label_016 = $Button_Frame -> Label ( -text=>'', -relief=>'flat' ) -> pack(-anchor=>'w', -side=>'left', -padx=>2);
my $w_Button_017 = $Button_Frame -> Button ( -text=>'|%|', -relief=>'raised' ) -> pack(-anchor=>'w', -padx=>2, -side=>'left');
MainLoop;

#===vptk end===< DO NOT CODE ABOVE THIS LINE >===
# calbacks:
sub say_hello
{
  print "Hello!\n";
}
