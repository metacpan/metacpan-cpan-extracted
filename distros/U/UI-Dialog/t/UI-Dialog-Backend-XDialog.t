use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::XDialog' ); }
require_ok( 'UI::Dialog::Backend::XDialog' );

#########################

eval { new UI::Dialog::Backend::XDialog(test_mode=>1); };
if ( $@ ) {
  if ($@ =~ m!binary could not be found!) {
    diag("Tests skipped, backend binary not found.");
  } else {
    diag("An unknown error occurred while trying to use backend: ".$@);
  }
  done_testing();
} else {

  my $obj = new UI::Dialog::Backend::XDialog(test_mode=>1);
  isa_ok( $obj, 'UI::Dialog::Backend::XDialog' );

  my @methods = qw( new state ra rs rv nautilus xosd beep clear
                    yesno msgbox inputbox password textbox menu
                    checklist radiolist fselect dselect
                    state combobox
                    rangebox rangesbox2 rangesbox3 spinbox spinsbox2
                    spinsbox3 buildlist treeview calendar timebox
                    inputsbox2 inputsbox3 passwords2 passwords3
                    msgbox infobox textbox editbox logbox tailbox
                    progress_start progress_inc progress_dec
                    progress_set progress_stop gauge_start gauge_inc
                    gauge_dec gauge_set gauge_text gauge_stop );
  can_ok( 'UI::Dialog::Backend::XDialog', @methods );

  # Track $bin is needed to validate the command line constructs
  my $bin = $obj->get_bin();

  #
  #: Test the standard dialog widgets
  #

  #: Test the yes/no prompt
  $obj->yesno( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
               width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --yesno TEXT 16 64'
    );

  #: Test the message box
  $obj->msgbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --msgbox TEXT 16 64'
    );

  #: Test the info box
  $obj->infobox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --infobox TEXT 16 64 5000'
    );

  #: Test the input box
  $obj->inputbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                  width => 64, height => 16, entry => ENTRY );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --inputbox TEXT 16 64 ENTRY'
    );

  #: Test the password box
  $obj->password( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                  width => 64, height => 16, entry => "ENTRY" );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --password --inputbox TEXT 16 64 ENTRY'
    );

  #: Test the text file box
  $obj->textbox( title=>"TITLE", backtitle => "BACKTITLE", path => "$0",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --textbox t/UI-Dialog-Backend-XDialog.t 16 64'
    );

  #: Test the menu prompt
  $obj->menu( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
              width => 64, height => 16,
              list => [ "tag0", "item0", "tag1", "item1" ] );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --separate-output --menu TEXT 16 64 5  tag0 item0 tag1 item1'
    );

  #: Test the checklist
  $obj->checklist( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --separate-output --checklist TEXT 16 64 5  tag0 item0 off tag1 item1 on'
    );

  #: Test the radiolist
  $obj->radiolist( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --separate-output --radiolist TEXT 16 64 5  tag0 item0 off tag1 item1 on'
    );

  #
  #: Test the non-standard but supported XDialog widgets
  #

  #: Test the file selector
  $obj->fselect( title=>"TITLE", backtitle => "BACKTITLE", path => "$0",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --fselect t/UI-Dialog-Backend-XDialog.t 16 64'
    );

  #: Test the calendar
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $mon += 1;
  $year += 1900;
  $obj->calendar( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                  width => 64, height => 4,
                  day => $mday, month => $mon, year => $year
                );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --separate-output --calendar TEXT 4 64 '.$mday.' '.$mon.' '.$year
    );

  #: Test the time box
  $obj->timebox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                 width => 64, height => 4,
                 hour => 16, minute => 20, second => 42
               );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --separate-output --timebox TEXT 4 64 16 20 42'
    );

  #: Test the tail box
  $obj->tailbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                 width => 64, height => 16, path => $0
               );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --button-style default --tailbox '.$0.' 16 64'
    );

  #
  #: Now test the trust-input feature for the XDialog backend.
  #

  $obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
                backtitle => 'BACKTITLE: `head -1 '.$0.'`',
                text => 'TEXT: $(head -1 '.$0.')',
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.q| --title 'TITLE: `head -1 t/UI-Dialog-Backend-XDialog.t`' --backtitle 'BACKTITLE: `head -1 t/UI-Dialog-Backend-XDialog.t`' --button-style default --msgbox 'TEXT: $(head -1 t/UI-Dialog-Backend-XDialog.t)' 16 64|
    );

  $obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
                backtitle => 'BACKTITLE: `head -1 '.$0.'`',
                text => 'TEXT: $(head -1 '.$0.')',
                'trust-input' => 1,
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.q| --title "TITLE: `head -1 t/UI-Dialog-Backend-XDialog.t`" --backtitle "BACKTITLE: `head -1 t/UI-Dialog-Backend-XDialog.t`" --button-style default --msgbox "TEXT: $(head -1 t/UI-Dialog-Backend-XDialog.t)" "16" "64"|
    );

  #
  #: Testing completed
  #

  done_testing();
}
