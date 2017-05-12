use Test::More qw(no_plan);
use Win32::Resources qw(LoadResource);

my $test_exe = 't/test_1.exe';

my $data = Win32::Resources::LoadResource(
	filename => $test_exe,
	type => RT_RCDATA,
	name => 'bar',
	language => '0',
);
is($data, 'bar...', "bar is bar...");

$data = LoadResource(
	filename => $test_exe,
	path => '24/1/1033',
);
like($data, qr/<\?xml/, "XP manifest ok");
