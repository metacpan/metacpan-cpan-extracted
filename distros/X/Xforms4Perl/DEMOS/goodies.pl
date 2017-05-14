#!/usr/bin/perl
#/* This demo program uses the routines in the
#   goodies section, that help you create easy
#   forms in an even easier way.
#*/

use X11::Xforms;
#use Forms_GOODIES;

  fl_initialize("FormDemo");
  ($ver_rev, $ver, $rev) = fl_library_version();

  if( fl_show_question("Do you want bold font ?",1)) {
     fl_set_goodies_font(FL_BOLD_STYLE,FL_DEFAULT_SIZE);
  }

  fl_show_messages("This is a test program\nfor the goodies of the \nforms library");

  fl_show_alert("Alert", "Alert form can be used to inform",
                "recoverable errors", 0);

  exit(0) if (fl_show_question("Do you want to quit?",0));

  $str1 = fl_show_input("Give a string:","");
  fl_show_message("You typed:","",$str1);
  if ($ver_rev == 84) {
  	$choice = fl_show_choice("Pick a choice",3,"One","Two","Three",2);
  } else {
  	$choice = fl_show_choices("Pick a choice",3,"One","Two","Three",2);
  }
  if ($choice == 1) {
     fl_show_message("You typed: One","","");
  } elsif ($choice == 2) {
     fl_show_message("You typed: Two","","");
  } elsif ($choice == 3) {
     fl_show_message("You typed: Three","","");
  } else {
     fl_show_message("An error occured!","","");
  }
  $str2 = fl_show_input("Give another string:",$str1);
  fl_show_message("You typed:","",$str2);
  fl_show_messages("Good Bye");
