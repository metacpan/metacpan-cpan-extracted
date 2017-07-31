
use strict;
use warnings;
use Math::Int64 qw(int64 :native_if_available);
use Time::Moment::Epoch;
use Test::Most;

my $PROG = 'blib/script/convert_epoch';

my @tests = (
	{
		obs => "$PROG 1234567890",
		exp => "2009-02-13T23:31:30Z",
	},
	{
		obs => "$PROG --reverse 2009-02-13T23:31:30Z",
		exp => 1234567890,
	},
	{
		obs => "$PROG -r -c windows_file 2010-03-04T14:50:16.559001600Z",
		exp => int64('129121878165590016'),
	},
);

for my $t (@tests) {
	chomp(my $obs = `$t->{obs}`);
	is $obs, $t->{exp}, $t->{obs};
}

done_testing;
