# Need to suppress warinings ?
BEGIN { $^W = 0; $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use sapnwrfc;
use Data::Dumper;
$loaded = 1;
print "ok 1\n";                                                                                     

SAPNW::Rfc->load_config;
my $conn = SAPNW::Rfc->rfc_connect;

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
my $rd = $conn->function_lookup("RPY_PROGRAM_READ");
#print STDERR "The FunctionDescriptor: ".Dumper($rd)."\n\n\n";
print ref($rd) eq 'SAPNW::RFC::FunctionDescriptor' ? "ok 2" : "not ok 2", "\n";
my $rc = $rd->create_function_call;
#print STDERR "The FunctionCall: ".Dumper($rc)."\n\n\n";
print ref($rc) eq 'SAPNW::RFC::FunctionCall' ? "ok 3" : "not ok 3", "\n";
$rc->PROGRAM_NAME("SAPLGRFC");
print $rc->PROGRAM_NAME eq "SAPLGRFC" ? "ok 4" : "not ok 4", "\n";
print STDERR "PROGRAM_NAME: ".$rc->PROGRAM_NAME."\n";
print $rc->invoke ? "ok 5" : "not ok 5", "\n";
#print STDERR "invoke result: ".Dumper($rc)."\n";
my ($progname) = $rc->PROG_INF->{'PROGNAME'} =~ /^(\S+)/;
print $progname eq "SAPLGRFC" ? "ok 6" : "not ok 6", "\n";
print scalar($rc->SOURCE_EXTENDED) > 10  ? "ok 7" : "not ok 7", "\n";
my $cnt = scalar grep(/LGRFCUXX/, map { $_->{LINE} } @{$rc->SOURCE_EXTENDED});
print $cnt == 1 ? "ok 8" : "not ok 8", "\n";
print $conn->disconnect ? "ok 9" : "not ok 9", "\n";

