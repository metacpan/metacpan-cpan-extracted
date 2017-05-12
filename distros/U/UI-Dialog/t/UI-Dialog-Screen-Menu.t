use Test::More;
BEGIN { use_ok( 'UI::Dialog::Screen::Menu' ); }
require_ok( 'UI::Dialog::Screen::Menu' );

# #########################

eval { new UI::Dialog::Screen::Menu(test_mode=>1); };
if ( $@ ) {
  diag("Unable to load UI::Dialog::Screen::Menu: ".$@);
  done_testing();
} else {
  my $obj = UI::Dialog::Screen::Menu->new();
  isa_ok( $obj, 'UI::Dialog::Screen::Menu' );

  my @methods =
    qw( new run
        break_loop is_looping
        add_menu_item get_menu_items
        del_menu_item set_menu_item
     );
  can_ok( 'UI::Dialog::Screen::Menu', @methods );
  done_testing();
}
