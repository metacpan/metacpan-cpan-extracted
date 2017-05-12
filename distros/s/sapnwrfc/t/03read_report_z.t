use Test::More;
use constant ITER => 50;

plan tests => (ITER * 8 + ITER * 6 + 2 + 1);
use_ok("sapnwrfc");

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
SAPNW::Rfc->load_config;

foreach (1..ITER) {
  my $conn = SAPNW::Rfc->rfc_connect;
  my $rd = $conn->function_lookup("RPY_PROGRAM_READ");
  ok(ref($rd) eq 'SAPNW::RFC::FunctionDescriptor');
  my $rc = $rd->create_function_call;
  ok(ref($rc) eq 'SAPNW::RFC::FunctionCall');
  $rc->PROGRAM_NAME("SAPLGRFC");
  ok($rc->PROGRAM_NAME eq "SAPLGRFC");
  ok($rc->invoke);
  my ($progname) = $rc->PROG_INF->{'PROGNAME'} =~ /^(\S+)/;
  ok($progname eq "SAPLGRFC");
  ok(scalar($rc->SOURCE_EXTENDED) > 10);
  my $cnt = scalar grep(/LGRFCUXX/, map { $_->{LINE} } @{$rc->SOURCE_EXTENDED});
  ok($cnt == 1);
  ok($conn->disconnect);
}


my $conn = SAPNW::Rfc->rfc_connect;
my $rd = $conn->function_lookup("RPY_PROGRAM_READ");
ok(ref($rd) eq 'SAPNW::RFC::FunctionDescriptor');
foreach (1..ITER) {
  my $rc = $rd->create_function_call;
  ok(ref($rc) eq 'SAPNW::RFC::FunctionCall');
  $rc->PROGRAM_NAME("SAPLGRFC");
  ok($rc->PROGRAM_NAME eq "SAPLGRFC");
  ok($rc->invoke);
  my ($progname) = $rc->PROG_INF->{'PROGNAME'} =~ /^(\S+)/;
  ok($progname eq "SAPLGRFC");
  ok(scalar($rc->SOURCE_EXTENDED) > 10);
  my $cnt = scalar grep(/LGRFCUXX/, map { $_->{LINE} } @{$rc->SOURCE_EXTENDED});
  ok($cnt == 1);
}
ok($conn->disconnect);
