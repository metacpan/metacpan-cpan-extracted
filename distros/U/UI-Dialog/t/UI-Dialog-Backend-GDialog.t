use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::GDialog' ); }
require_ok( 'UI::Dialog::Backend::GDialog' );

#########################

eval { new UI::Dialog::Backend::GDialog(test_mode=>1); };
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
  my $obj = new UI::Dialog::Backend::GDialog
    ( test_mode => 1 );
  isa_ok( $obj, 'UI::Dialog::Backend::GDialog' );

  #: Check for all the standard UI::Dialog backend methods
  my @methods = qw( new state ra rs rv nautilus xosd beep clear
                    yesno msgbox inputbox password textbox menu
                    checklist radiolist fselect dselect );
  can_ok( 'UI::Dialog::Backend::GDialog', @methods );

  # Track $bin is needed to validate the command line constructs
  my $bin = $obj->get_bin();

  #
  #: Test the standard dialog widgets
  #

  #: Test the yes/no prompt
  $obj->yesno( title=>"TITLE", text => "TEXT",
               width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --yesno TEXT 16 64'
    );

  $obj->msgbox( title=>"TITLE", text => "TEXT",
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --scrolltext --msgbox TEXT 16 64'
    );

  $obj->infobox( title=>"TITLE", text => "TEXT",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --scrolltext --infobox TEXT 16 64'
    );

  $obj->inputbox( title=>"TITLE", text => "TEXT",
                  width => 64, height => 16, entry => "ENTRY" );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --inputbox TEXT 16 64 ENTRY'
    );

  $obj->textbox( title=>"TITLE", path => "$0",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title TITLE --textbox '.$0.' 16 64'
    );

  $obj->menu( title=>"TITLE", text => "TEXT",
              width => 64, height => 16,
              list => [ "tag0", "item0", "tag1", "item1" ] );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --menu TEXT 16 64 ''  tag0 item0 tag1 item1|
    );

  $obj->checklist( title=>"TITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --separate-output --checklist TEXT 16 64 ''  tag0 item0 off tag1 item1 on|
    );

  $obj->radiolist( title=>"TITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --separate-output --radiolist TEXT 16 64 ''  tag0 item0 off tag1 item1 on|
    );


  #
  # Now test the trust-input feature for the GDialog backend.
  #

  $obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
                backtitle => 'BACKTITLE: `head -1 '.$0.'`',
                text => 'TEXT: $(head -1 '.$0.')',
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.q| --title 'TITLE: `head -1 |.$0.q|`' --scrolltext --msgbox 'TEXT: $(head -1 |.$0.q|)' 16 64|
    );

  $obj->msgbox( title=>'TITLE: `head -1 '.$0.'`',
                backtitle => 'BACKTITLE: `head -1 '.$0.'`',
                text => 'TEXT: $(head -1 '.$0.')',
                'trust-input' => 1,
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.' --title "TITLE: `head -1 '.$0.'`" --scrolltext --msgbox "TEXT: $(head -1 '.$0.')" "16" "64"'
    );

  done_testing();
}
