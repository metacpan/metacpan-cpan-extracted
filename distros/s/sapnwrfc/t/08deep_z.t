use Test::More;
use Data::Dumper;
use constant ITER => 50;

plan tests => (ITER * 17 + ITER * 12 + 5 + 1);
use_ok("sapnwrfc");

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
SAPNW::Rfc->load_config;

foreach (1..ITER) {
  eval {
    my $conn = SAPNW::Rfc->rfc_connect;
    my $fds = $conn->function_lookup("STFC_DEEP_STRUCTURE");
    ok(ref($fds) eq 'SAPNW::RFC::FunctionDescriptor');
    ok($fds->name eq 'STFC_DEEP_STRUCTURE');
    my $fs = $fds->create_function_call;
    ok(ref($fs) eq 'SAPNW::RFC::FunctionCall');
    ok($fs->name eq 'STFC_DEEP_STRUCTURE');
    $fs->IMPORTSTRUCT({ 'I' => 123, 'C' => 'AbCdEf', 'STR' =>  'The quick brown fox ...', 'XSTR' => pack("H*", "deadbeef")});
    ok($fs->invoke);
    ok($fs->ECHOSTRUCT->{'I'} == 123);
    my ($c) = $fs->ECHOSTRUCT->{'C'} =~ /^(\S+)/;
    ok($c eq 'AbCdEf');
    my $str = $fs->ECHOSTRUCT->{'STR'};
		$str =~ s/\s+$//;
    ok($str eq 'The quick brown fox ...');
    my $fts = $conn->function_lookup("STFC_DEEP_TABLE");
    ok(ref($fts) eq 'SAPNW::RFC::FunctionDescriptor');
    ok($fts->name eq 'STFC_DEEP_TABLE');
    my $ft = $fts->create_function_call;
    ok(ref($ft) eq 'SAPNW::RFC::FunctionCall');
    ok($ft->name eq 'STFC_DEEP_TABLE');
    $ft->IMPORT_TAB([{ 'I' => 123, 'C' => 'AbCdEf', 'STR' =>  'The quick brown fox ...', 'XSTR' => pack("H*", "deadbeef")}]);
    ok($ft->invoke);
    ok($ft->EXPORT_TAB->[0]->{'I'} == 123);
    ($c) = $ft->EXPORT_TAB->[0]->{'C'} =~ /^(\S+)/;
	#print STDERR "EXPORT_TAB ROW: ".Dumper($ft->EXPORT_TAB->[0])."\n";
    ok($c eq 'AbCdEf');
    $str = $ft->EXPORT_TAB->[0]->{'STR'};
		$str =~ s/\s+$//;
    ok($str eq 'The quick brown fox ...');
    ok($conn->disconnect);
	};
	if ($@) {
	  print STDERR "RFC Failure in STFC_DEEP_* (set 1): $@\n";
	}
}


eval {
  my $conn = SAPNW::Rfc->rfc_connect;
  my $fds = $conn->function_lookup("STFC_DEEP_STRUCTURE");
  ok(ref($fds) eq 'SAPNW::RFC::FunctionDescriptor');
  ok($fds->name eq 'STFC_DEEP_STRUCTURE');
  my $fts = $conn->function_lookup("STFC_DEEP_TABLE");
  ok(ref($fts) eq 'SAPNW::RFC::FunctionDescriptor');
  ok($fts->name eq 'STFC_DEEP_TABLE');
  foreach (1..ITER) {
    my $fs = $fds->create_function_call;
    ok(ref($fs) eq 'SAPNW::RFC::FunctionCall');
    ok($fs->name eq 'STFC_DEEP_STRUCTURE');
    $fs->IMPORTSTRUCT({ 'I' => 123, 'C' => 'AbCdEf', 'STR' =>  'The quick brown fox ...', 'XSTR' => pack("H*", "deadbeef")});
    ok($fs->invoke);
    ok($fs->ECHOSTRUCT->{'I'} == 123);
    my ($c) = $fs->ECHOSTRUCT->{'C'} =~ /^(\S+)/;
    ok($c eq 'AbCdEf');
    my $str = $fs->ECHOSTRUCT->{'STR'};
		$str =~ s/\s+$//;
    ok($str eq 'The quick brown fox ...');
    my $ft = $fts->create_function_call;
    ok(ref($ft) eq 'SAPNW::RFC::FunctionCall');
    ok($ft->name eq 'STFC_DEEP_TABLE');
    $ft->IMPORT_TAB([{ 'I' => 123, 'C' => 'AbCdEf', 'STR' =>  'The quick brown fox ...', 'XSTR' => pack("H*", "deadbeef")}]);
    ok($ft->invoke);
    ok($ft->EXPORT_TAB->[0]->{'I'} == 123);
    ($c) = $ft->EXPORT_TAB->[0]->{'C'} =~ /^(\S+)/;
	#print STDERR "EXPORT_TAB ROW: ".Dumper($ft->EXPORT_TAB->[0])."\n";
    ok($c eq 'AbCdEf');
    $str = $ft->EXPORT_TAB->[0]->{'STR'};
		$str =~ s/\s+$//;
    ok($str eq 'The quick brown fox ...');
  }
  ok($conn->disconnect);
};
if ($@) {
	print STDERR "RFC Failure in STFC_DEEP_* (set 2): $@\n";
}
