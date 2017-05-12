use Test::More 'no_plan';
use Data::Compare qw( Compare );

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

use_ok('perfSONAR_PS::DB::RRD');
use perfSONAR_PS::DB::RRD;

$RRDEXE = `which rrdtool`;
chomp($RRDEXE);
%RRDVARIABLES = ("ds" => "");
$RRDERROR = 1;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::RRD::new tests

system("./t/testfiles/createrrd");

$rrdb1 = perfSONAR_PS::DB::RRD->new({ path => $RRDEXE, name => "./t/testfiles/testrrd1.rrd", dss => $RRDVARIABLES, error => $RRDERROR });
$rrdb2 = perfSONAR_PS::DB::RRD->new;
$rrdb3 = perfSONAR_PS::DB::RRD->new;
ok(defined $rrdb1, "DB::RRD::new - Round robin database object 1 defined");
ok(defined $rrdb2, "DB::RRD::new - Round robin database object 2 defined");
ok(defined $rrdb3, "DB::RRD::new - Round robin database object 3 defined");

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::RRD::setPath

$rrdb2->setPath({ path => $RRDEXE });
$rrdb3->setPath({ path => $RRDEXE });

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::RRD::setFile

$rrdb2->setFile({ file => "./t/testfiles/testrrd2.rrd" });
$rrdb3->setFile({ file => "./t/testfiles/testrrd3.rrd" });

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::RRD::setVariables

$rrdb2->setVariables({ dss => $RRDVARIABLES });

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::RRD::setVariable

@variables = sort(keys(%RRDVARIABLES));
foreach $var (@variables)
{
	$rrdb3->setVariable({ ds => $var });
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::RRD::setError

$rrdb2->setError({ error => $RRDERROR });
$rrdb3->setError({ error => $RRDERROR });

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::RRD::query

$rrdb1->openDB;
%result1 = $rrdb1->query({ cf => "AVERAGE", resolution => 1, start => 1000000000, end => 1000000004 });
$rrdb1->closeDB;
$rrdb2->openDB;
%result2 = $rrdb2->query({ cf => "AVERAGE", resolution => 1, start => 1000000000, end => 1000000005 });
$rrdb2->closeDB;
$rrdb3->openDB;
%result3 = $rrdb3->query({ cf => "AVERAGE", resolution => 1, start => 2000000202, end => 2000000204 });
$rrdb3->closeDB;

%expectedResult1 = ("1000000001" => {"ds" => "1.3370000000e+03"}, "1000000002" => {"ds" => "3.1400000000e+00"}, "1000000003" => {"ds" => "2.7100000000e+00"}, "1000000004" => {"ds" => "4.2000000000e+01"}, "1000000005" => {"ds" => "8.9000000000e-01"});
#%expectedResult2 = ("1000000002" => {"ds" => "6.7007000000e+02"}, "1000000004" => {"ds" => "2.2355000000e+01"}, "1000000006" => {"ds" => "nan"});
%expectedResult2 = ("1000000002" => {"ds" => "6.7007000000e+02"}, "1000000004" => {"ds" => "2.2355000000e+01"}, "1000000006" => {"ds" => "nan"});
%expectedResult3 = ("2000000203" => {"ds" => "2.7100000000e+00"}, "2000000204" => {"ds" => "4.2000000000e+01"}, "2000000205" => {"ds" => "8.9000000000e-01"});
ok(checkQuery(\%result1, \%expectedResult1), "DB::RRD::query - rrdb1");
ok(checkQuery(\%result2, \%expectedResult2), "DB::RRD::query - rrdb2");
ok(checkQuery(\%result3, \%expectedResult3), "DB::RRD::query - rrdb3");

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::RRD::insert

$rrdb1->openDB;
$rrdb1->insert({ time => "1000000006", ds => "ds", value => 17 });
$rrdb1->insertCommit;
$expectedResult1{"1000000006"} = {"ds" => "1.7000000000e+01"};
$rrdb1->closeDB;
$rrdb2->openDB;
$rrdb2->insert({ time => "1000000006", ds => "ds", value => 17 });
$rrdb2->insertCommit;
$expectedResult2{"1000000006"} = {"ds" => "8.9450000000e+00"};
$rrdb2->closeDB;
$rrdb3->openDB;
$rrdb3->insert({ time => "2000000206", ds => "ds", value => 17 });
$rrdb3->insertCommit;
$expectedResult3{"2000000206"} = {"ds" => "1.7000000000e+01"};
$rrdb3->closeDB;

$rrdb1->openDB;
%result1 = $rrdb1->query({ cf => "AVERAGE", resolution => 1, start => 1000000000, end => 1000000005 });
$rrdb1->closeDB;
$rrdb2->openDB;
%result2 = $rrdb2->query({ cf => "AVERAGE", resolution => 1, start => 1000000000, end => 1000000005 });
$rrdb2->closeDB;
$rrdb3->openDB;
%result3 = $rrdb3->query({ cf => "AVERAGE", resolution => 1, start => 2000000202, end => 2000000205 });
$rrdb3->closeDB;

ok(checkQuery(\%result1, \%expectedResult1), "DB::RRD::insert - rrdb1");
ok(checkQuery(\%result2, \%expectedResult2), "DB::RRD::insert - rrdb2");
ok(checkQuery(\%result3, \%expectedResult3), "DB::RRD::insert - rrdb3");

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DB::RRD::firstValue, DB::RRD::lastValue

$rrdb1->openDB;
is($rrdb1->firstValue, 1000000006 - (1000 - 1), "DB::RRD::firstValue - rrdb1");
is($rrdb1->lastValue, 1000000006, "DB::RRD::lastValue - rrdb1");
$rrdb1->closeDB;
$rrdb2->openDB;
is($rrdb2->firstValue, 1000000006 - 2 * (1000 - 1), "DB::RRD::firstValue - rrdb2");
is($rrdb2->lastValue, 1000000006, "DB::RRD::lastValue - rrdb2");
$rrdb2->closeDB;
$rrdb3->openDB;
is($rrdb3->firstValue, 2000000206 - (2000 - 1), "DB::RRD::firstValue - rrdb3");
is($rrdb3->lastValue, 2000000206, "DB::RRD::lastValue - rrdb3");
$rrdb3->closeDB;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

sub checkQuery
{
	my %h1 = %{$_[0]};
	my %h2 = %{$_[1]};
	my @keys1 = sort(keys(%h1));
	my @keys2 = sort(keys(%h2));
	if(Compare(\@keys1, \@keys2) == 0) {return 0;}
	foreach $key (@keys1)
	{
		if(Compare($h1{$key}, $h2{$key}) == 0) {return 0;}
	}
	return 1;
}

