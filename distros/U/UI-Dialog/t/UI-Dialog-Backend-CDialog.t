use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::CDialog' ); }
require_ok( 'UI::Dialog::Backend::CDialog' );

#########################

#
#: First, need to make sure /usr/bin/dialog exists and if the backend
#: module is even usable.
#

eval { new UI::Dialog::Backend::CDialog(test_mode=>1); };
if ( $@ ) {
  if ($@ =~ m!binary could not be found!) {
    diag("Tests skipped, backend binary not found.");
  }
  else {
    diag("An unknown error occurred while trying to use backend: ".$@);
  }
  done_testing();
}
else {

  #: Setup obj in test_mode
  my $obj = new UI::Dialog::Backend::CDialog( test_mode => 1 );
  isa_ok( $obj, 'UI::Dialog::Backend::CDialog' );

  #: Check for all the standard UI::Dialog backend methods
  my @methods = qw( new state ra rs rv nautilus xosd beep clear
                    yesno msgbox inputbox password textbox menu
                    checklist radiolist fselect dselect );
  can_ok( 'UI::Dialog::Backend::CDialog', @methods );

  # Track $bin is needed to validate the command line constructs
  my $bin = $obj->get_bin();

  #
  #: Test the standard dialog widgets
  #

  #: Test the yes/no prompt
  $obj->yesno( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
               width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --yesno TEXT 16 64'
    );

  #: Test the message box
  $obj->msgbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --msgbox TEXT 16 64'
    );

  #: Test the info box
  $obj->infobox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --infobox TEXT 16 64'
    );

  #: Test the input box
  $obj->inputbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                  width => 64, height => 16, entry => ENTRY );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --inputbox TEXT 16 64 ENTRY'
    );

  #: Test the password box
  $obj->password( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                  width => 64, height => 16, entry => "ENTRY" );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --insecure --passwordbox TEXT 16 64 ENTRY'
    );

  #: Test the password box
  $obj->password( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                  width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --passwordbox TEXT 16 64 \'\''
    );

  #: Test the text file box
  $obj->textbox( title=>"TITLE", backtitle => "BACKTITLE", path => "$0",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --scrolltext --textbox t/UI-Dialog-Backend-CDialog.t 16 64'
    );

  #: Test the menu prompt
  $obj->menu( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
              width => 64, height => 16,
              list => [ "tag0", "item0", "tag1", "item1" ] );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --menu TEXT 16 64 5  tag0 item0 tag1 item1'
    );

  #: Test the checklist
  $obj->checklist( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --separate-output --checklist TEXT 16 64 5  tag0 item0 off tag1 item1 on'
    );

  #: Test the radiolist
  $obj->radiolist( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --radiolist TEXT 16 64 5  tag0 item0 off tag1 item1 on'
    );


  #
  #: Test the non-standard but supported CDialog widgets
  #

  #: Test the file selector
  $obj->fselect( title=>"TITLE", backtitle => "BACKTITLE", path => "$0",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --fselect t/UI-Dialog-Backend-CDialog.t 16 64'
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
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --calendar TEXT 5 64 '.$mday.' '.$mon.' '.$year
    );

  #: Test the time box
  $obj->timebox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                 width => 64, height => 4,
                 hour => 16, minute => 20, second => 42
               );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --timebox TEXT 4 64 16 20 42'
    );

  #: Test the tail box
  $obj->tailbox( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                 width => 64, height => 16, path => $0
               );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --tailbox '.$0.' 16 64'
    );

  #: Test the tail box bg
  $obj->tailboxbg( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
                   width => 64, height => 16, path => $0
                 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --tailboxbg '.$0.' 16 64'
    );

  #: Test the form
  $obj->form
    ( title=>"TITLE", backtitle => "BACKTITLE", text => "TEXT",
      width => 64, height => 16,
      list =>
      [
       [ "label0", 1, 1], ["item0", 1, 10, 10, 10 ],
       [ "label1", 2, 1], ["item1", 2, 10, 10, 10 ],
      ]
    );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --backtitle BACKTITLE --colors --cr-wrap --form TEXT 16 64 5  "label0" "1" "1" "item0" "1" "10" "10" "10" "label1" "2" "1" "item1" "2" "10" "10" "10"'
    );

  #: Note that the guage/progress widget is not unit-testable at this time.
  #: This is due to the fact that the gauge_start() method opens a background
  #: command pipe so that IPC can happen to update the text and progress of
  #: the widget.

  #
  #: Now test the trust-input feature for the CDialog backend.
  #

  $obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
                backtitle => 'BACKTITLE: `head -1 '.$0.'`',
                text => 'TEXT: $(head -1 '.$0.')',
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.q| --title 'TITLE: `head -1 t/UI-Dialog-Backend-CDialog.t`' --backtitle 'BACKTITLE: `head -1 t/UI-Dialog-Backend-CDialog.t`' --colors --cr-wrap --msgbox 'TEXT: $(head -1 t/UI-Dialog-Backend-CDialog.t)' 16 64|
    );

  $obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
                backtitle => 'BACKTITLE: `head -1 '.$0.'`',
                text => 'TEXT: $(head -1 '.$0.')',
                'trust-input' => 1,
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.q| --title "TITLE: `head -1 t/UI-Dialog-Backend-CDialog.t`" --backtitle "BACKTITLE: `head -1 t/UI-Dialog-Backend-CDialog.t`" --colors --cr-wrap --msgbox "TEXT: $(head -1 t/UI-Dialog-Backend-CDialog.t)" "16" "64"|
    );

  #
  #: Testing completed
  #

  done_testing();
}
