use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::XOSD' ); }
require_ok( 'UI::Dialog::Backend::XOSD' );

# #########################

eval { new UI::Dialog::Backend::XOSD (test_mode=>1); };
if ( $@ ) {
  if ($@ =~ m!binary could not be found!) {
    diag("Tests skipped, backend binary not found.");
  } else {
    diag("Tests skipped, unknown backend error: ".$@);
  }
  done_testing();
} else {
  my $obj = UI::Dialog::Backend::XOSD->new();
  isa_ok( $obj, 'UI::Dialog::Backend::XOSD' );

  my @methods =
    qw( new line file gauge
        display_start display_stop
        display_text display_gauge
     );
  can_ok( 'UI::Dialog::Backend::XOSD', @methods );
  done_testing();
}
