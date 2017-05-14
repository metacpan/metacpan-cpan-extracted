#!/usr/bin/perl
#/* This demo shows the use of io callbacks.  */

use X11::Xforms;

$form = undef;


  pipe(PREAD, PWRITE);

  if ($kid = fork() == 0)
  {
		sub_proc();
  }
  else
  {
  		fl_initialize("FormDemo");
  		create_form();
  		fl_show_form($form,FL_PLACE_CENTER,FL_FULLBORDER,NULL);

        fl_add_io_callback(*PREAD, FL_READ, io_cb, 0);

        fl_do_forms();
        kill(9, $kid);
        fl_hide_form($form);
  }

sub create_form
{
  $form = fl_bgn_form(FL_NO_BOX,30,30);
  fl_add_box(FL_UP_BOX,0,0,30,30,"");
  fl_add_button(FL_NORMAL_BUTTON,0,0,30,30,"Quit");
  fl_end_form();
}

sub io_cb {

    my($file, $data) = @_;

    $line = <$file>;
    print "Line: $line\n";

}

sub sub_proc {

    select(PWRITE); $| = 1;
    while(1) {
		sleep(5);
    	print PWRITE "from child: I'm still here!!!\n";
	}
}
