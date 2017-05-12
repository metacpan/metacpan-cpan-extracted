use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::Zenity' ); }
require_ok( 'UI::Dialog::Backend::Zenity' );

#########################

eval { new UI::Dialog::Backend::Zenity(test_mode=>1); };
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

  my $obj = new UI::Dialog::Backend::Zenity
    ( test_mode => 1 );
  isa_ok( $obj, 'UI::Dialog::Backend::Zenity' );

  my $bin = $obj->get_bin();

  my @methods = qw( new state ra rs rv nautilus xosd beep clear
                    yesno msgbox inputbox password textbox menu
                    checklist radiolist fselect dselect );
  can_ok( 'UI::Dialog::Backend::Zenity', @methods );

  $obj->yesno( title=>"TITLE", text => "TEXT",
               width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --width 64 --height 16 --question --text TEXT|
    );

  $obj->msgbox( title=>"TITLE", text => "TEXT",
                width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --width 64 --height 16 --info --text TEXT|
    );

  $obj->infobox( title=>"TITLE", text => "TEXT",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --width 64 --height 16 --info --text TEXT|
    );

  $obj->inputbox( title=>"TITLE", text => "TEXT",
                  width => 64, height => 16, entry => "ENTRY" );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --width 64 --height 16 --entry --entry-text ENTRY --text TEXT|
    );

  $obj->password( title=>"TITLE", text => "TEXT",
                  width => 64, height => 16, entry => "ENTRY" );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --width 64 --height 16 --entry --hide-text --entry-text ENTRY --text TEXT|
    );

  $obj->textbox( title=>"TITLE", path => "$0",
                 width => 64, height => 16 );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --width 64 --height 16 --text-info --filename t/UI-Dialog-Backend-Zenity.t|
    );

  $obj->menu( title=>"TITLE", text => "TEXT",
              width => 64, height => 16,
              list => [ "tag0", "item0", "tag1", "item1" ] );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --width 64 --height 16 --list --separator '\n' --column " " --column " " "tag0" "item0" "tag1" "item1"|
    );

  $obj->checklist( title=>"TITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --width 64 --height 16 --list --checklist --separator '\n' --column " " --column " " --column " " "FALSE" "tag0" "item0" "TRUE" "tag1" "item1"|
    );

  $obj->radiolist( title=>"TITLE", text => "TEXT",
                   width => 64, height => 16,
                   list => [ "tag0", [ "item0", 0 ], "tag1", [ "item1", 1 ] ] );
  is( $obj->get_unit_test_result(),
      $bin.q| --title TITLE --width 64 --height 16 --list --radiolist --separator '\n' --column " " --column " " --column " " "FALSE" "tag0" "item0" "TRUE" "tag1" "item1"|
    );

  done_testing();
}
