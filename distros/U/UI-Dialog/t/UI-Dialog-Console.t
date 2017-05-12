use Test::More;
BEGIN { use_ok( 'UI::Dialog::Console' ); }
require_ok( 'UI::Dialog::Console' );

# #########################

eval { new UI::Dialog::Console(test_mode=>1); };
if ( $@ ) {
  diag("Unable to load UI::Dialog::Console: ".$@);
  done_testing();
} else {
  my $obj = UI::Dialog::Console->new();
  isa_ok( $obj, 'UI::Dialog::Console' );

  my @methods = qw( new state ra rs rv nautilus xosd beep clear
                    yesno msgbox inputbox password textbox menu
                    checklist radiolist fselect dselect );
  can_ok( 'UI::Dialog::Console', @methods );
  done_testing();
}
