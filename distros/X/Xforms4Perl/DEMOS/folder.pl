#!/usr/bin/perl
use X11::Xforms;

#
# This demonstartes the building and use of folders. It also demonstrates how
# to use the fdui field of the form structure in order to build an 
# application on the same lines as done by fdesign.
#


   fl_initialize("Folder example");
   $fd_mainform = create_form_mainform();

   make_folder($fd_mainform->{"folder"});

   fl_show_form($fd_mainform->{"mainform"},FL_PLACE_CENTER,FL_FULLBORDER,"buttonform");
   fl_do_forms() while(1);
   exit 0;

sub done_cb
{
    exit(0);
}

sub hide_show_cb
{
   ($ob, $data) = @_;
   $fdui = $ob->form->fdui;

   $data ? fl_show_object($fdui->{"folder"}) : fl_hide_object($fdui->{"folder"});
}

sub reshow_cb
{
   ($ob, $data) = @_;
   fl_hide_form($ob->form);
   fl_show_form($ob->form,FL_PLACE_CENTER,FL_FULLBORDER,"buttonform");
}

sub set_cb
{
   ($ob, $data) = @_;
    $fdui = $ob->form->fdui;
    $n = fl_get_active_folder_number($fdui->{"folder"});
    fl_set_folder_bynumber($fdui->{"folder"}, ($n%5)+1);
}

sub deactivate_cb
{
   ($ob, $data) = @_;
    $fdui = $ob->form->fdui;


    if($fdui->{"folder"}->active > 0)
    {
        fl_set_object_label($ob,"Activate");
        fl_deactivate_object($fdui->{"folder"});
    }
    else
    {
        fl_set_object_label($ob,"Deactivate");
        fl_activate_object($fdui->{"folder"});
    }
}

sub make_folder
{
   my($folder) = @_;

   $fd_buttonform = create_form_buttonform();
   $fd_staticform = create_form_staticform();
   $fd_valuatorform = create_form_valuatorform();
   $fd_choiceform = create_form_choiceform();
   $fd_inputform = create_form_inputform();

   fl_addto_menu($fd_choiceform->{"pulldown"},"MenuEntry1|MenuEntry2|MenuEntry3|MenuEntry4");
   fl_addto_menu($fd_choiceform->{"pushmenu"},"MuEntry1|MenuEntry2|MenuEntry3");
   fl_addto_choice($fd_choiceform->{"choice"},"Choice1|Choice2|Choice3|Choice4|Choice5|Choice6");

   fl_load_browser($fd_choiceform->{"browser"},"folder.pl");

   fl_addto_tabfolder($folder,"ButtonObj", $fd_buttonform->{"buttonform"});
   fl_addto_tabfolder($folder,"StaticObj", $fd_staticform->{"staticform"});
   fl_addto_tabfolder($folder,"ValuatorObj", $fd_valuatorform->{"valuatorform"});
   fl_addto_tabfolder($folder,"ChoiceObj", $fd_choiceform->{"choiceform"});
   fl_addto_tabfolder($folder,"InputObj", $fd_inputform->{"inputform"});
}

sub create_form_buttonform
{
#  %fdui = {
#	buttonform => undef
#  };

  $fdui->{"buttonform"} = fl_bgn_form(FL_NO_BOX, 430, 210);
  $obj = fl_add_box(FL_FLAT_BOX,0,0,430,210,"");
  $obj = fl_add_button(FL_NORMAL_BUTTON,30,151,80,30,"Button");
  $obj = fl_add_roundbutton(FL_PUSH_BUTTON,40,91,100,30,"RoundButton");
  $obj = fl_add_round3dbutton(FL_PUSH_BUTTON,135,151,110,30,"Round3DButton");
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
  $obj = fl_add_checkbutton(FL_PUSH_BUTTON,170,111,110,30,"CheckButton");
  $obj = fl_add_lightbutton(FL_PUSH_BUTTON,30,31,100,30,"LightButton");
  $obj = fl_add_pixmapbutton(FL_NORMAL_BUTTON,320,36,80,80,"PixmapButton");
    fl_set_pixmapbutton_file($obj, "porsche.xpm");
  $obj = fl_add_button(FL_NORMAL_BUTTON,185,26,100,30,"Button");
    fl_set_object_boxtype($obj,FL_ROUNDED3D_UPBOX);
  $obj = fl_add_lightbutton(FL_PUSH_BUTTON,290,146,100,30,"Button");
    fl_set_object_boxtype($obj,FL_EMBOSSED_BOX);
  $obj = fl_add_button(FL_NORMAL_BUTTON,175,71,60,25,"Button");
    fl_set_object_boxtype($obj,FL_SHADOW_BOX);
    fl_set_object_color($obj,FL_COL1,FL_SLATEBLUE);
  fl_end_form();

  $fdui->{"buttonform"}->fdui($fdui);

  return $fdui;
}

sub create_form_staticform
{
#  %fdui = {
#	staticform => undef
#  }; 

  $fdui->{"staticform"} = fl_bgn_form(FL_NO_BOX, 431, 211);
  $obj = fl_add_box(FL_FLAT_BOX,0,0,431,211,"");
    fl_set_object_color($obj,FL_INDIANRED,FL_INDIANRED);
    fl_set_object_lcolor($obj,FL_INDIANRED);
  $obj = fl_add_box(FL_UP_BOX,40,40,60,45,"A Box");
  $obj = fl_add_labelframe(FL_ENGRAVED_FRAME,130,30,120,55,"LabelFrame");
    fl_set_object_color($obj,FL_BLACK,FL_INDIANRED);
    fl_set_object_lstyle($obj,FL_BOLD_STYLE);
  $obj = fl_add_chart(FL_BAR_CHART,270,20,130,105,"Chart");
    $c = FL_BLACK;
    fl_add_chart_value($obj,15.0,"item 1",++$c);
    fl_add_chart_value($obj,5.0,"item 2",++$c);
    fl_add_chart_value($obj,0.0,"item 3",++$c);
    fl_add_chart_value($obj,-10.,"item 4",++$c);
    fl_add_chart_value($obj,25.0,"item 5",++$c);
    fl_add_chart_value($obj,12.0,"item 6",++$c);
  $obj = fl_add_clock(FL_ANALOG_CLOCK,30,100,85,85,"Clock");
    fl_set_object_color($obj,FL_COL1,FL_RIGHT_BCOL);
  $obj = fl_add_bitmap(FL_NORMAL_BITMAP,150,140,30,25,"Bitmap");
    fl_set_bitmap_file($obj, "srs.xbm");
  $obj = fl_add_pixmap(FL_NORMAL_PIXMAP,230,120,40,40,"Pixmap");
    fl_set_pixmap_file($obj, "crab.xpm");
  $obj = fl_add_text(FL_NORMAL_TEXT,310,150,70,25,"Text");
    fl_set_object_boxtype($obj,FL_BORDER_BOX);
    fl_set_object_lalign($obj,FL_ALIGN_LEFT|FL_ALIGN_INSIDE);
  fl_end_form();

  $fdui->{"staticform"}->fdui($fdui);

  return $fdui;
}

sub create_form_mainform
{

#  %fdui = {
#	mainform => undef,
#	done => undef,
#	hide => undef,
#	show => undef,
#	reshow => undef,
#	folder => undef,
#	set => undef,
#	deactivate => undef
#  };

  $fdui->{"mainform"} = fl_bgn_form(FL_NO_BOX, 461, 311);
  $obj = fl_add_box(FL_UP_BOX,0,0,461,311,"");
  $fdui->{"done"} = $obj = fl_add_button(FL_NORMAL_BUTTON,381,270,64,25,"Done");
	fl_set_object_callback($obj,"done_cb",0);
  $fdui->{"hide"} = $obj = fl_add_button(FL_NORMAL_BUTTON,15,269,64,27,"Hide");
    fl_set_button_shortcut($obj,"#H",1);
    fl_set_object_callback($obj,"hide_show_cb",0);
  $fdui->{"show"} = $obj = fl_add_button(FL_NORMAL_BUTTON,79,269,64,27,"Show");
    fl_set_button_shortcut($obj,"#S",1);
    fl_set_object_callback($obj,"hide_show_cb",1);
  $fdui->{"reshow"} = $obj = fl_add_button(FL_NORMAL_BUTTON,155,269,64,27,"ReShow");
    fl_set_button_shortcut($obj,"#R",1);
    fl_set_object_callback($obj,"reshow_cb",0);
  $fdui->{"folder"} = $obj = fl_add_tabfolder(FL_TOP_TABFOLDER,15,21,435,230,"");
  $fdui->{"set"} = $obj = fl_add_button(FL_NORMAL_BUTTON,232,269,64,27,"Set");
    fl_set_object_callback($obj,"set_cb",0);
  $fdui->{"deactivate"} = $obj = fl_add_button(FL_NORMAL_BUTTON,296,269,69,27,"Deactivate");
    fl_set_object_callback($obj,"deactivate_cb",0);
  fl_end_form();

  $fdui->{"mainform"}->fdui($fdui);

  return $fdui;
}

sub create_form_valuatorform
{

# %fdui = {
#	valuatorform => undef
#  };

  $fdui->{"valuatorform"} = fl_bgn_form(FL_NO_BOX, 431, 211);
  $obj = fl_add_box(FL_FLAT_BOX,0,0,431,211,"");
  $obj = fl_add_positioner(FL_NORMAL_POSITIONER,300,102,90,80,"");
    fl_set_positioner_xvalue($obj, 0.679012);
    fl_set_positioner_yvalue($obj, 0.71831);
  $obj = fl_add_valslider(FL_HOR_NICE_SLIDER,70,20,240,20,"");
    fl_set_object_boxtype($obj,FL_FLAT_BOX);
    fl_set_object_color($obj,FL_COL1,FL_RIGHT_BCOL);
    fl_set_slider_value($obj, 0.87);
  $obj = fl_add_counter(FL_NORMAL_COUNTER,285,54,110,20,"");
    fl_set_counter_value($obj, -1.0);
  $obj = fl_add_slider(FL_VERT_NICE_SLIDER,20,30,20,160,"");
    fl_set_object_boxtype($obj,FL_FLAT_BOX);
    fl_set_object_color($obj,FL_COL1,FL_RED);
    fl_set_slider_value($obj, 0.49);
  $obj = fl_add_valslider(FL_HOR_BROWSER_SLIDER,70,170,150,23,"");
    fl_set_slider_size($obj, 0.10);
  $obj = fl_add_slider(FL_HOR_FILL_SLIDER,69,57,159,27,"");
    fl_set_object_color($obj,FL_COL1,FL_SLATEBLUE);
    fl_set_slider_value($obj, 0.25);
  $obj = fl_add_dial(FL_LINE_DIAL,147,93,72,60,"");
    fl_set_object_boxtype($obj,FL_UP_BOX);
    fl_set_object_color($obj,FL_COL1,FL_BLUE);
  fl_end_form();

  $fdui->{"valuatorform"}->fdui($fdui);

  return $fdui;
}

sub create_form_choiceform
{
#  %fdui = {
#	 choiceform => undef,
#	 pulldown => undef,
#	 choice => undef,
#	 browser => undef,
#	 pushmenu => undef
#  };

  $fdui->{"choiceform"} = fl_bgn_form(FL_NO_BOX, 431, 211);
  $obj = fl_add_box(FL_FLAT_BOX,0,0,431,211,"");
  $fdui->{"pulldown"} = $obj = fl_add_menu(FL_PULLDOWN_MENU,45,36,45,21,"Menu");
    fl_set_object_boxtype($obj,FL_FLAT_BOX);
    fl_set_object_color($obj,FL_COL1,FL_LEFT_BCOL);
  $fdui->{"choice"} = $obj = fl_add_choice(FL_NORMAL_CHOICE2,24,93,111,27,"");
  $fdui->{"browser"} = $obj = fl_add_browser(FL_HOLD_BROWSER,257,14,154,179,"");
  $fdui->{"pushmenu"} = $obj = fl_add_menu(FL_PUSH_MENU,152,51,75,26,"Menu");
    fl_set_object_boxtype($obj,FL_UP_BOX);
  fl_end_form();

  $fdui->{"choiceform"}->fdui($fdui);

  return $fdui;
}

sub create_form_inputform
{
#  %fdui = {
#	 inputform => undef
#  };

  $fdui->{"inputform"} = fl_bgn_form(FL_NO_BOX, 430, 210);
  $obj = fl_add_box(FL_FLAT_BOX,0,0,430,210,"");
  $obj = fl_add_input(FL_MULTILINE_INPUT,70,20,280,90,"MultiLine\nInput");
  $obj = fl_add_input(FL_NORMAL_INPUT,80,132,250,34,"Input");
  fl_end_form();

  $fdui->{"inputform"}->fdui($fdui);

  return $fdui;
}

