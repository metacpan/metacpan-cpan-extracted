use Test::More;
use constant ITER => 50;

plan tests => (ITER * 8 + ITER * 5 + 3 + 1);
use_ok("sapnwrfc");

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
SAPNW::Rfc->load_config;

foreach my $iter (1..ITER) {
  eval {
    my $conn = SAPNW::Rfc->rfc_connect;
    my $rd = $conn->function_lookup("STFC_CHANGING");
    ok(ref($rd) eq 'SAPNW::RFC::FunctionDescriptor');
    ok($rd->name eq 'STFC_CHANGING');
    my $rc = $rd->create_function_call;
    ok(ref($rc) eq 'SAPNW::RFC::FunctionCall');
    ok($rc->name eq 'STFC_CHANGING');
    $rc->START_VALUE($iter);
    $rc->COUNTER($iter);
    ok($rc->invoke);
    ok($rc->RESULT == $iter + $iter);
    ok($rc->COUNTER == $iter + 1);
    ok($conn->disconnect);
	};
	if ($@) {
	  print STDERR "RFC Failure in STFC_CHANGING (set 1): $@\n";
	}
}


eval {
  my $conn = SAPNW::Rfc->rfc_connect;
  my $rd = $conn->function_lookup("STFC_CHANGING");
  ok(ref($rd) eq 'SAPNW::RFC::FunctionDescriptor');
  ok($rd->name eq 'STFC_CHANGING');
  foreach my $iter (1..ITER) {
    my $rc = $rd->create_function_call;
    ok(ref($rc) eq 'SAPNW::RFC::FunctionCall');
    ok($rc->name eq 'STFC_CHANGING');
    $rc->START_VALUE($iter);
    $rc->COUNTER($iter);
    ok($rc->invoke);
    ok($rc->RESULT == $iter + $iter);
    ok($rc->COUNTER == $iter + 1);
  }
  ok($conn->disconnect);
};
if ($@) {
  print STDERR "RFC Failure in STFC_CHANGING (set 2): $@\n";
}
