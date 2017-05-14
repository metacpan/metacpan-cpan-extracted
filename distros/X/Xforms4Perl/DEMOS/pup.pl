#!/usr/bin/perl
use X11::Xforms;

#/* Demo: complete pop-ups. 
# * test font/cursor change
# * test attaching pup to menu 
# */

$subm = -1;
$m = -1;
$ssm = undef; 

$n = undef;
$n1 = -1;
$n2 = -1;

$pup = undef;
$done = $pret = $b1 = $b2 = $b3 = $menu = undef;

    $aa = X11::Xforms::FLOpt::new;
    $mask = FL_PDVisual;

    $aa->vclass(FL_DefaultVisual);
    fl_set_defaults($mask, $aa);

    fl_initialize("FormDemo");

    create_form_pup();

    fl_set_object_posthandler($b1, "post");
    fl_set_object_posthandler($b2, "post");
    fl_set_object_posthandler($b3, "post");

    fl_show_form($pup, FL_PLACE_MOUSE, FL_TRANSIENT,"PupDemo");
    init_menu();

    fl_do_forms();
    exit 0;

#/* post-handler */
sub post
{
    my($ob, $ev, $mx, $y, $key, $xev) = @_;

    if($n1 == -1)
    {    
      $n1 = fl_defpup(FL_ObjWin($ob),"line1|line2");
      fl_setpup_shadow($n1,0);
      fl_setpup_bw($n1,0);
      fl_setpup_pad($n1,3,0);

      $n2 = fl_defpup(FL_ObjWin($ob),"button1|button2");
      fl_setpup_shadow($n2,0);
      fl_setpup_bw($n2,-1);
      fl_setpup_pad($n2,3,0);
    }

    if($ev == FL_ENTER)
    {
       if($ob==$b3) 
	   {
         fl_show_oneliner("button3",$ob->form->x+$ob->x,
                         $ob->form->y+$ob->y + $ob->h + 5);
       }
       else
       {
          fl_setpup_position($ob->form->x+$ob->x, $ob->form->y+$ob->y+$ob->h+5);
          fl_showpup(($ob==$b1) ? $n1:$n2);
       }
    }
    elsif($ev != FL_MOTION)
    {
       if($ob==$b3) 
	   {
         fl_hide_oneliner();
       }
       else
	   {
         fl_hidepup(($ob==$b1) ?  $n1:$n2);
       }
    }

    return 0;
}


sub show_return_val
{
	my($i) = @_;
    if($i >= 0)
    {
       $buf = sprintf("Returned %d(%s)",$i, fl_getpup_text($m,$i));
    }
    else
    {
       $buf = sprintf($buf,"Returned %d",$i);
    }

    fl_set_object_label($pret, $buf);
}

sub ssm_cb
{
	my($a) = @_;

   show_return_val($a);
   return $a;
}

sub do_pup
{
   my($ob, $q) = @_;

   if($subm == -1)
   {
      $ssm  = fl_newpup(FL_ObjWin($ob));
      $subm = fl_newpup(FL_ObjWin($ob));
      $m    = fl_newpup(FL_ObjWin($ob));

#/*      fl_addtopup(ssm,"SubSubM%F%t",ssm_cb);*/
      fl_addtopup($ssm,"SSMItem20%x20%R1");
      fl_addtopup($ssm,"SSMItem21%x21%r1");
      fl_addtopup($ssm,"SSMItem22%x22%r1%l");
      fl_addtopup($ssm,"SSMitem30%x30%R2");
      fl_addtopup($ssm,"SSMItem31%x31%r2");
      fl_addtopup($ssm,"SSMItem32%x32%r2");

#/*      fl_addtopup(subm,"SubMenu%t");*/
      fl_addtopup($subm,"SMItemA\tAlt-A%x10"); 
		fl_setpup_shortcut($subm, 10, "#a");
      fl_addtopup($subm,"SMItemB\tAlt-B%x11");
		fl_setpup_shortcut($subm, 11, "#b");
      fl_addtopup($subm,"SMItemC\tAlt-C%x12");
		fl_setpup_shortcut($subm, 12, "#c");
      fl_addtopup($subm,"SMItemD\tAlt-F5%x13");
		fl_setpup_submenu($subm, 13, $ssm);
		fl_setpup_shortcut($subm, 13, "#&5");
      fl_addtopup($subm,"SMItemE\tAlt-E%x14");
		fl_setpup_shortcut($subm, 14, "#E");

      fl_setpup_mode($subm, 14, FL_PUP_GREY);

	$i = 0;
      fl_addtopup($m,"PopUP%t"); $i++;
      fl_addtopup($m,"MenuItem1");
		fl_setpup_shortcut($subm, $i++, "1#1");

      fl_addtopup($m,"MenuItem2");
		fl_setpup_shortcut($subm, $i, "2#2");
        fl_setpup_submenu($m, $i++, $subm);
      fl_addtopup($m,"MenuItem3");
		fl_setpup_shortcut($subm, $i, "3#3");
      fl_addtopup($m,"MenuItem4");
		fl_setpup_shortcut($subm, $i, "4#4");
   }


   if(fl_get_button_numb($ob) >= FL_SHORTCUT)
   {
      fl_setpup_position($ob->form->x + $ob->x, 
                      $ob->form->y + $ob->y + $ob->h); 
   }

   show_return_val(fl_dopup($m));

#   /* test if changing size/style ok */
   $n = !$n;
   fl_setpup_fontsize($n ? 14:12);
   fl_setpup_fontstyle($n ? FL_TIMES_STYLE:FL_BOLDITALIC_STYLE);
   fl_setpup_cursor($m, $n ? XC_hand2:XC_sb_right_arrow);
}

sub init_menu
{
    $mm = fl_newpup(fl_default_win());
    fl_setpup_bw($mm, -2);
    fl_setpup_shadow($mm, 0);
    $smm = fl_newpup(0);
    fl_setpup_shadow($smm, 0);

    fl_addtopup($mm,"MenuItem1|MenuItem2|MenuItem3");
    fl_addtopup($smm,"SubItem1%x11|SubItem2%x12|SubItem3%x13");
	fl_setpup_submenu($mm, 2, $smm);

#    /* attach pup to menu */
    fl_set_menu_popup($menu, $mm);
}


sub do_menu(FL_OBJECT *ob, long data)
{
	my($ob, $data) = @_;

    if(fl_get_menu($ob) >= 0)
    {
       $buf = sprintf("%d (%s)", fl_get_menu($ob), fl_get_menu_text($ob));
    }
    else
    {
       $buf = sprintf($buf,"%d", fl_get_menu($ob));
    }

    fl_set_object_label($pret, $buf);
}

sub done_cb
{
   exit(0);
}

sub create_form_pup
{
  return if ($pup);
  $pup = fl_bgn_form(FL_UP_BOX,260,210);
  $done = $obj = fl_add_button(FL_NORMAL_BUTTON,150,150,90,35,"Done");
    fl_set_object_callback($obj,"done_cb", 0);
  $obj = fl_add_button(FL_MENU_BUTTON,30,90,100,30,"PopUp");
  fl_set_button_shortcut($obj,"Pp#p",1);
  fl_set_object_callback($obj, "do_pup", 0);
  $menu = $obj = fl_add_menu(FL_PULLDOWN_MENU,160,95,60,25,"Menu");
  fl_set_object_callback($obj, "do_menu", 0);
  $pret = $obj = fl_add_text(FL_NORMAL_TEXT,20,60,220,30,"");
    fl_set_object_lalign($obj,FL_ALIGN_CENTER);
  $b1 = fl_add_button(FL_NORMAL_BUTTON, 20, 10, 60, 30,"Button1");
  $b2 = fl_add_button(FL_NORMAL_BUTTON, 90, 10, 60, 30,"Button2");
  $b3 = fl_add_button(FL_NORMAL_BUTTON, 160, 10, 60, 30,"Button3");
  fl_end_form();
}
