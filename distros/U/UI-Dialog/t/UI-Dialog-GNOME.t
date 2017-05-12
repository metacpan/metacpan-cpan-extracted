use Test::More;
BEGIN { use_ok( 'UI::Dialog::GNOME' ); }
require_ok( 'UI::Dialog::GNOME' );

# #########################

eval { new UI::Dialog::GNOME(test_mode=>1); };
if ( $@ ) {
  if ($@ =~ m!unable to load suitable backend!) {
    diag("Tests skipped, suitable backend not found.");
  } else {
    diag("An unknown error occurred while trying to use: ".$@);
  }
  done_testing();
} else {
  my $obj = UI::Dialog::GNOME->new();
  isa_ok( $obj, 'UI::Dialog::GNOME' );

  my @methods = qw( new state ra rs rv nautilus xosd beep clear
                    yesno msgbox inputbox password textbox menu
                    checklist radiolist fselect dselect );
  can_ok( 'UI::Dialog::GNOME', @methods );
  done_testing();
}
