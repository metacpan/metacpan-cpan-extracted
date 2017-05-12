use Test::More;
BEGIN { use_ok( 'UI::Dialog::Gauged' ); }
require_ok( 'UI::Dialog::Gauged' );

# #########################

eval { new UI::Dialog::Gauged(test_mode=>1); };
if ( $@ ) {
  diag("Unable to load UI::Dialog::Gauged: ".$@);
  done_testing();
} else {
  my $obj = UI::Dialog::Gauged->new();
  isa_ok( $obj, 'UI::Dialog::Gauged' );

  my @methods = qw( new state ra rs rv nautilus xosd beep clear
                    yesno msgbox inputbox password textbox menu
                    checklist radiolist fselect dselect );
  can_ok( 'UI::Dialog::Gauged', @methods );
  done_testing();
}
