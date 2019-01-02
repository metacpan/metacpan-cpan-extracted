use Test::More;
BEGIN {
	*CORE::GLOBAL::time = sub { 1531922097; }; 
}
	
use Time::Random;
{
	my %okay = (
		'18-07-18 13:54:57' => 1,
		'18-07-18 13:54:56' => 1,
		'18-07-18 13:54:55' => 1,	
	);

	my $random = Time::Random::time_random(
		from => '1531922094',
		strftime => '%y-%m-%d %H:%M:%S'
	);

	is($okay{$random}, 1, 'expected value');

	my $hash = Time::Random::time_random({})->epoch;
	my $v = time;
	$v -= 86400;
	is($v < $hash, 1, 'expected value');
}

done_testing();
