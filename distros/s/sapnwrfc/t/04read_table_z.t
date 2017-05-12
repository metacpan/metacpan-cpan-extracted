use Test::More;
use constant ITER => 50;

plan tests => (ITER * 9 + ITER * 6 + 3 + 1);
use_ok("sapnwrfc");

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
SAPNW::Rfc->load_config;

foreach (1..ITER) {
  eval {
    my $conn = SAPNW::Rfc->rfc_connect;
    my $rd = $conn->function_lookup("RFC_READ_TABLE");
    ok(ref($rd) eq 'SAPNW::RFC::FunctionDescriptor');
    ok($rd->name eq 'RFC_READ_TABLE');
    my $rc = $rd->create_function_call;
    ok(ref($rc) eq 'SAPNW::RFC::FunctionCall');
    $rc->QUERY_TABLE("T000");
    ok($rc->QUERY_TABLE eq "T000");
    $rc->DELIMITER("|");
    ok($rc->DELIMITER eq "|");
    $rc->ROWCOUNT(2);
    ok($rc->ROWCOUNT == 2);
    ok($rc->invoke);
    ok(scalar(@{$rc->DATA}) == 2);
    ok($conn->disconnect);
	};
	if ($@) {
	  print STDERR "RFC Failure in RFC_READ_TABLE (set 1): $@\n";
	}
}


eval {
  my $conn = SAPNW::Rfc->rfc_connect;
  my $rd = $conn->function_lookup("RFC_READ_TABLE");
  ok(ref($rd) eq 'SAPNW::RFC::FunctionDescriptor');
  ok($rd->name eq 'RFC_READ_TABLE');
  foreach (1..ITER) {
    my $rc = $rd->create_function_call;
    ok(ref($rc) eq 'SAPNW::RFC::FunctionCall');
    $rc->QUERY_TABLE("T000");
    ok($rc->QUERY_TABLE eq "T000");
    $rc->DELIMITER("|");
    ok($rc->DELIMITER eq "|");
    $rc->ROWCOUNT(2);
    ok($rc->ROWCOUNT == 2);
    ok($rc->invoke);
    ok(scalar(@{$rc->DATA}) == 2);
  }
  ok($conn->disconnect);
};
if ($@) {
  print STDERR "RFC Failure in RFC_READ_TABLE (set 2): $@\n";
}
