use Test::More;

use Time::Random qw/all/;

use Data::Dumper;
my $from = time() - 604800;

my %unique;

for (1..100) {
	my $random = time_random(
		from => $from,
	);
	is $from < $random->epoch, 1, $_ . ': generated epoch is after the passed from epoch';
	$unique{$random->epoch}++;
}

is (scalar keys %unique, 100, '100 unique');

my $random = time_random(
	from => '1531922094',
	to => '1531922097',
	strftime => '%y-%m-%d %H:%M:%S'
);

my %okay = (
	'18-07-18 13:54:57' => 1,
	'18-07-18 13:54:56' => 1,
	'18-07-18 13:54:55' => 1,	
);
is($okay{$random}, 1, 'expected value');

my $st = time_random(
	from => '18-07-18 13:54:55',
	to => $random,
	strptime => '%y-%m-%d %H:%M:%S',
	strftime => '%y-%m-%d %H:%M:%S'
);
is($okay{$st}, 1, 'expected value');

done_testing();
