# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 13 };
use Time::Interval;
ok(1); # If we made it this far, we're ok.

#########################

#test getInterval
my $str1 = "1/15/03 12:34:32 EDT 2003";
my $str2 = "4/25/03 11:24:00 EDT 2003";
print "testing getInterval between:\n\t$str1\n\t$str2\n";
if (my $data = getInterval($str1,$str2)){
	foreach (keys %{$data}){ print "[$_]: $data->{$_}\n"; }
	ok(1);
}else{
	ok(0);
}

#test convertInterval
my %data = (
	'days'		=> 70,
	'hours'		=> 16,
	'minutes'	=> 56,
	'seconds'	=> 18
);

print "testing convertInterval on:\n";
foreach (keys %data){ print "[$_]: $data{$_}\n"; }
foreach ('days','hours','minutes','seconds'){
	my $num = convertInterval(
		ConvertTo	=> $_,
		%data
	) || ok(0);
	print "converting to $_ ...: $num\n";
	ok(1);
}

#test parseInterval
print "testing parseInterval (data):\n";
foreach ('days','hours','minutes','seconds'){
	print "12345 $_ is: ...\n";
	my $string = parseInterval(
		$_		=> 12345,
		String	=> 1
	) || ok(0);
	print "\t$string\n";
	ok(1);
}

#test parseInterval
print "testing parseInterval w/abbreviated string (data):\n";
foreach ('days','hours','minutes','seconds'){
	print "12345 $_ is: ...\n";
	my $string = parseInterval(
		$_		=> 12345,
		Small	=> 1
	) || ok(0);
	print "\t$string\n";
	ok(1);
}

#test coalesce
print "testing coalesce on: \n";
my @date_ranges  = (
#	[ "5/13/04 10:00:00 EDT", "5/13/04 11:00:00 EDT" ],
#	[ "5/13/04 13:00:00 EDT", "5/13/04 14:00:00 EDT" ],
#	[ "5/13/04 10:50:00 EDT", "5/13/04 12:00:00 EDT" ],
#	[ "5/10/04 10:50:00 EDT", "5/11/04 12:00:00 EDT" ],
#	[ "5/13/04 9:50:00 EDT",  "5/13/04 11:00:00 EDT" ],
	[ "20040429 11:34:16", "20040430 02:19:30" ],
	[ "20040429 11:34:16", "20040501 02:19:31" ],
	[ "20040429 11:34:16", "20040502 02:19:31" ],
	[ "20040429 11:34:16", "20040503 02:19:31" ],
	[ "20040429 11:34:16", "20040504 02:19:31" ],
	[ "20040429 11:34:16", "20040504 14:04:58" ]

);
foreach (@date_ranges){ print $_->[0], " - ", $_->[1], "\n"; }

$tmp = coalesce(\@date_ranges);
print "coalesced dates:\n";
foreach (@{$tmp}){
	print $_->[0], " - ", $_->[1], "\n";
}
ok(1);

#test fractional seconds
print "testing fractional second rounding ...\n";
my $string = parseInterval( 'seconds' => 1.61803398875, 'Small' => 1 ) || ok(0);
print "rounded ok: " . $string . "\n";
ok(1);
