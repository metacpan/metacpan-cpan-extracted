
use strict;
use warnings;
use Time::Moment::Epoch;
use Test::Most;

my $PROG = 'blib/script/is_epoch';

my @tests = (
	{
		obs => "$PROG 1234567890 --min=2005 --max=2017",
		exp => "2016-12-22T00:22:36Z	(1234567890, decimal, dos)
2009-02-13T23:31:30Z	(1234567890, decimal, unix)
2007-03-16T23:31:30Z	(1234567890, decimal, google_calendar)
2006-02-22T15:04:32Z	(1234567890, hexadecimal, dos)"
	},
	{
		obs => "$PROG 33c41a44-6cea-11e7-907b-a6006ad3dba0",
		exp => "2017-07-20T01:24:40.472634Z	(33c41a44-6cea-11e7-907b-a6006ad3dba0, uuid_v1, uuid_v1)",
	},
	{
		obs => "$PROG 0123456789abcdef --min=1900 --max=2600",
		exp => "2598-01-06T14:06:56.486895Z	(0123456789abcdef, hexadecimal, symbian)
2517-07-28T00:25:51.921914625Z	(0123456789abcdef, hexadecimal_swapped, apfs)
2031-10-05T04:24:02Z	(0123456789abcdef, hexadecimal_swapped, dos)
1972-08-06T21:45:29.216486895Z	(0123456789abcdef, hexadecimal, apfs)",
	},
	{
		obs => "$PROG d907020005000d0017001f001e000000",
		exp => "2009-02-13T23:31:30Z	(d907020005000d0017001f001e000000, hex128bit, windows_system)",
	},
);

for my $t (@tests) {
	chomp(my $obs = `$t->{obs}`);
	is $obs, $t->{exp}, $t->{obs};
}

done_testing;
