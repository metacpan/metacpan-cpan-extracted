use Test::More;
BEGIN { use_ok( 'UI::Dialog::Backend::Nautilus' ); }
require_ok( 'UI::Dialog::Backend::Nautilus' );

# #########################

eval { new UI::Dialog::Backend::Nautilus (test_mode=>1); };
if ( $@ ) {
  if ($@ =~ m!binary could not be found!) {
    diag("Tests skipped, backend binary not found.");
  }
  else {
    diag("Tests skipped, unknown backend error: ".$@);
  }
  done_testing();
}
else {
  my $obj = UI::Dialog::Backend::Nautilus->new();
  isa_ok( $obj, 'UI::Dialog::Backend::Nautilus' );

  my @methods =
    qw( new
        uri_unescape
        paths uris
        path uris
        geometry
     );
  can_ok( 'UI::Dialog::Backend::Nautilus', @methods );
  done_testing();
}
