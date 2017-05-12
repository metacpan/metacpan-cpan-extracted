use Test::More;
use constant ITER => 50;

plan tests => (ITER + (ITER * 4 * 7) + (ITER * 4 * 7) + 3 + 1);
use_ok("sapnwrfc");

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
SAPNW::Rfc->load_config;

foreach (1..ITER) {
  print STDERR "Iteration: $_ of set 1\n";
	eval {
    my $conn = SAPNW::Rfc->rfc_connect;
  	foreach my $f ("STFC_CHANGING", "STFC_XSTRING", "RFC_READ_TABLE", "RFC_READ_REPORT", "RPY_PROGRAM_READ", "RFC_PING", "RFC_SYSTEM_INFO") {
      my $rd = $conn->function_lookup($f);
      ok(ref($rd) eq 'SAPNW::RFC::FunctionDescriptor');
      ok($rd->name eq $f);
      my $rc = $rd->create_function_call;
      ok(ref($rc) eq 'SAPNW::RFC::FunctionCall');
      ok($rc->name eq $f);
  	}
    ok($conn->disconnect);
	};
	if ($@) {
	  print STDERR "RFC Failure in function lookups (set 1): $@\n";
	}
}


eval {
  my $conn = SAPNW::Rfc->rfc_connect;
  my $rd = $conn->function_lookup("RFC_READ_TABLE");
  ok(ref($rd) eq 'SAPNW::RFC::FunctionDescriptor');
  ok($rd->name eq 'RFC_READ_TABLE');
  foreach (1..ITER) {
    print STDERR "Iteration: $_ of set 2\n";
  	foreach my $f ("STFC_CHANGING", "STFC_XSTRING", "RFC_READ_TABLE", "RFC_READ_REPORT", "RPY_PROGRAM_READ", "RFC_PING", "RFC_SYSTEM_INFO") {
      my $rd = $conn->function_lookup($f);
      ok(ref($rd) eq 'SAPNW::RFC::FunctionDescriptor');
      ok($rd->name eq $f);
      my $rc = $rd->create_function_call;
      ok(ref($rc) eq 'SAPNW::RFC::FunctionCall');
      ok($rc->name eq $f);
  	}
  }
  ok($conn->disconnect);
};
if ($@) {
  print STDERR "RFC Failure in function lookups (set 2): $@\n";
}
