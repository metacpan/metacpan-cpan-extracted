use Test::More;
use constant ITER => 50;
use Data::Dumper;
use utf8;
use sapnwrfc;

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
SAPNW::Rfc->load_config;
my $conn;
eval { $conn = SAPNW::Rfc->rfc_connect; };
if ($@) {
  print STDERR "RFC Failure to connect: $@\n";
	die $@;
}


eval {
my $fd = $conn->function_lookup("Z_TEST_DATA");
};
my $err = $@;
$conn->disconnect;
if ($err) {
  print STDERR "RFC Failure to find Z_TEST_DATA: $err\n";
	plan skip_all => "You do not have Z_TEST_DATA";
}

plan tests => (ITER * 34 + ITER * 31 + 3 + 1);
use_ok("sapnwrfc");

foreach (1..ITER) {
  eval {
    my $conn = SAPNW::Rfc->rfc_connect;
    my $fd = $conn->function_lookup("Z_TEST_DATA");
    ok(ref($fd) eq 'SAPNW::RFC::FunctionDescriptor');
    ok($fd->name eq 'Z_TEST_DATA');
    my $fc = $fd->create_function_call;
    ok(ref($fc) eq 'SAPNW::RFC::FunctionCall');
	ok($fc->name eq "Z_TEST_DATA");
    $fc->CHAR("German: öäüÖÄÜß");
    $fc->INT1(123);
    $fc->INT2(1234);
    $fc->INT4(123456);
    $fc->FLOAT('123456.00');
    $fc->NUMC('12345');
    $fc->DATE('20060709');
    $fc->TIME('200607');
    $fc->BCD('200607.123');
    $fc->ISTRUCT({ 'ZCHAR' => "German: öäüÖÄÜß", 'ZINT1' => 54, 'ZINT2' => 134, 'ZIT4' => 123456, 'ZFLT' => '123456.00', 'ZNUMC' => '12345', 'ZDATE' => '20060709', 'ZTIME' => '200607', 'ZBCD' => '200607.123' });
    $fc->DATA([{ 'ZCHAR' => "German: öäüÖÄÜß", 'ZINT1' => 54, 'ZINT2' => 134, 'ZIT4' => 123456, 'ZFLT' => '123456.00', 'ZNUMC' => '12345', 'ZDATE' => '20060709', 'ZTIME' => '200607', 'ZBCD' => '200607.123' }]);
    ok($fc->invoke);
		#print STDERR "DATA: ".Dumper($fc->DATA)."\n";
		#foreach my $row (@{$fc->DATA}) {
		#  print STDERR "row: ".Dumper($row)."\n";
		#}
    ok(scalar(@{$fc->DATA}) == 2);
	ok($fc->EINT1 == $fc->INT1);
	ok($fc->EINT2 == $fc->INT2);
	ok($fc->EINT4 == $fc->INT4);
	ok($fc->EFLOAT == $fc->FLOAT);
	ok($fc->ENUMC eq $fc->NUMC);
	ok($fc->EDATE eq $fc->DATE);
	ok($fc->ETIME eq $fc->TIME);
	ok($fc->EBCD == $fc->BCD);
	#print STDERR "EBCD: ".$fc->EBCD."\n";
	#print STDERR "EFLOAT: ".$fc->EFLOAT."\n";
	#print STDERR "CHAR: ".length($fc->CHAR)."#\n";
	#print STDERR "ECHAR: ".length($fc->ECHAR)."#\n";
    #print STDERR "ECHAR: ".$fc->ECHAR."#\n";
	my $echar = $fc->ECHAR;
	$echar =~ s/\s+$//;
	#print STDERR "echar: ".$echar."#\n";
    #print STDERR " char: ".$fc->CHAR."#\n";
	#print STDERR "FC: ".Dumper($fc)."\n";
	ok($echar eq $fc->CHAR);
	ok($fc->ESTRUCT->{ZINT1} == $fc->ISTRUCT->{ZINT1});
	ok($fc->ESTRUCT->{ZINT2} == $fc->ISTRUCT->{ZINT2});
	ok($fc->ESTRUCT->{ZIT4} == $fc->ISTRUCT->{ZIT4});
	ok($fc->ESTRUCT->{ZFLT} == $fc->ISTRUCT->{ZFLT});
	ok($fc->ESTRUCT->{ZBCD} == $fc->ISTRUCT->{ZBCD});
	ok($fc->ESTRUCT->{ZNUMC} eq $fc->ISTRUCT->{ZNUMC});
	ok($fc->ESTRUCT->{ZDATE} eq $fc->ISTRUCT->{ZDATE});
	ok($fc->ESTRUCT->{ZTIME} eq $fc->ISTRUCT->{ZTIME});
	$echar = $fc->ESTRUCT->{ZCHAR};
	$echar =~ s/\s+$//;
	ok($echar eq $fc->ISTRUCT->{ZCHAR});
	#print STDERR "RESULT: ".Dumper($fc->RESULT)."\n";
	#foreach my $row (@{$fc->RESULT}) {
	#  print STDERR "row: ".Dumper($row)."\n";
	#}
	ok($fc->DATA->[0]->{ZINT1} == $fc->ISTRUCT->{ZINT1});
	ok($fc->DATA->[0]->{ZINT2} == $fc->ISTRUCT->{ZINT2});
	ok($fc->DATA->[0]->{ZIT4} == $fc->ISTRUCT->{ZIT4});
	ok($fc->DATA->[0]->{ZFLT} == $fc->ISTRUCT->{ZFLT});
	ok($fc->DATA->[0]->{ZBCD} == $fc->ISTRUCT->{ZBCD});
	ok($fc->DATA->[0]->{ZNUMC} eq $fc->ISTRUCT->{ZNUMC});
	ok($fc->DATA->[0]->{ZDATE} eq $fc->ISTRUCT->{ZDATE});
	ok($fc->DATA->[0]->{ZTIME} eq $fc->ISTRUCT->{ZTIME});
	$echar = $fc->DATA->[0]->{ZCHAR};
	$echar =~ s/\s+$//;
	ok($echar eq $fc->ISTRUCT->{ZCHAR});
    ok($conn->disconnect);
	};
	if ($@) {
	  print STDERR "RFC Failure in Z_TEST_DATA (set 1): $@\n";
	}
}


eval {
  my $conn = SAPNW::Rfc->rfc_connect;
  my $fd = $conn->function_lookup("Z_TEST_DATA");
  ok(ref($fd) eq 'SAPNW::RFC::FunctionDescriptor');
  ok($fd->name eq 'Z_TEST_DATA');
  foreach (1..ITER) {
    my $fc = $fd->create_function_call;
    ok(ref($fc) eq 'SAPNW::RFC::FunctionCall');
		ok($fc->name eq "Z_TEST_DATA");
    $fc->CHAR("German: öäüÖÄÜß");
    $fc->INT1(123);
    $fc->INT2(1234);
    $fc->INT4(123456);
    $fc->FLOAT('123456.00');
    $fc->NUMC('12345');
    $fc->DATE('20060709');
    $fc->TIME('200607');
    $fc->BCD('200607.123');
    $fc->ISTRUCT({ 'ZCHAR' => "German: öäüÖÄÜß", 'ZINT1' => 54, 'ZINT2' => 134, 'ZIT4' => 123456, 'ZFLT' => '123456.00', 'ZNUMC' => '12345', 'ZDATE' => '20060709', 'ZTIME' => '200607', 'ZBCD' => '200607.123' });
    $fc->DATA([{ 'ZCHAR' => "German: öäüÖÄÜß", 'ZINT1' => 54, 'ZINT2' => 134, 'ZIT4' => 123456, 'ZFLT' => '123456.00', 'ZNUMC' => '12345', 'ZDATE' => '20060709', 'ZTIME' => '200607', 'ZBCD' => '200607.123' }]);
    ok($fc->invoke);
		#print STDERR "DATA: ".Dumper($fc->DATA)."\n";
		#foreach my $row (@{$fc->DATA}) {
		#  print STDERR "row: ".Dumper($row)."\n";
		#}
    ok(scalar(@{$fc->DATA}) == 2);
		ok($fc->EINT1 == $fc->INT1);
		ok($fc->EINT2 == $fc->INT2);
		ok($fc->EINT4 == $fc->INT4);
		ok($fc->EFLOAT == $fc->FLOAT);
		ok($fc->ENUMC eq $fc->NUMC);
		ok($fc->EDATE eq $fc->DATE);
		ok($fc->ETIME eq $fc->TIME);
		ok($fc->EBCD == $fc->BCD);
		#print STDERR "EBCD: ".$fc->EBCD."\n";
		#print STDERR "EFLOAT: ".$fc->EFLOAT."\n";
		#print STDERR "CHAR: ".$fc->CHAR."#\n";
		#print STDERR "ECHAR: ".$fc->ECHAR."#\n";
		my $echar = $fc->ECHAR;
		$echar =~ s/\s+$//;
		#print STDERR "echar: ".$echar."#\n";
		#print STDERR "FC: ".Dumper($fc)."\n";
		ok($echar eq $fc->CHAR);
		ok($fc->ESTRUCT->{ZINT1} == $fc->ISTRUCT->{ZINT1});
		ok($fc->ESTRUCT->{ZINT2} == $fc->ISTRUCT->{ZINT2});
		ok($fc->ESTRUCT->{ZIT4} == $fc->ISTRUCT->{ZIT4});
		ok($fc->ESTRUCT->{ZFLT} == $fc->ISTRUCT->{ZFLT});
		ok($fc->ESTRUCT->{ZBCD} == $fc->ISTRUCT->{ZBCD});
		ok($fc->ESTRUCT->{ZNUMC} eq $fc->ISTRUCT->{ZNUMC});
		ok($fc->ESTRUCT->{ZDATE} eq $fc->ISTRUCT->{ZDATE});
		ok($fc->ESTRUCT->{ZTIME} eq $fc->ISTRUCT->{ZTIME});
		$echar = $fc->ESTRUCT->{ZCHAR};
		$echar =~ s/\s+$//;
		ok($echar eq $fc->ISTRUCT->{ZCHAR});
		#print STDERR "RESULT: ".Dumper($fc->RESULT)."\n";
		#foreach my $row (@{$fc->RESULT}) {
		#  print STDERR "row: ".Dumper($row)."\n";
		#}
		ok($fc->DATA->[0]->{ZINT1} == $fc->ISTRUCT->{ZINT1});
		ok($fc->DATA->[0]->{ZINT2} == $fc->ISTRUCT->{ZINT2});
		ok($fc->DATA->[0]->{ZIT4} == $fc->ISTRUCT->{ZIT4});
		ok($fc->DATA->[0]->{ZFLT} == $fc->ISTRUCT->{ZFLT});
		ok($fc->DATA->[0]->{ZBCD} == $fc->ISTRUCT->{ZBCD});
		ok($fc->DATA->[0]->{ZNUMC} eq $fc->ISTRUCT->{ZNUMC});
		ok($fc->DATA->[0]->{ZDATE} eq $fc->ISTRUCT->{ZDATE});
		ok($fc->DATA->[0]->{ZTIME} eq $fc->ISTRUCT->{ZTIME});
		$echar = $fc->DATA->[0]->{ZCHAR};
		$echar =~ s/\s+$//;
		ok($echar eq $fc->ISTRUCT->{ZCHAR});
		#foreach my $row (@{$fc->RESULT}) {
		#  print STDERR "row: ".Dumper($row)."\n";
		#}
  }
  ok($conn->disconnect);
};
if ($@) {
  print STDERR "RFC Failure in Z_TEST_DATA (set 2): $@\n";
}
