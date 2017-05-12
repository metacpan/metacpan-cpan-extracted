use Test::More qw(no_plan);
use Win32::Resources::Update;
use File::Copy;

my $test_exe = 't/test_1.exe';
unlink($test_exe);
ok(copy('t/test.exe', $test_exe));

ok(my $exe = Win32::Resources::Update->new(
	filename => $test_exe,
), "create a Win32::Resources object");

ok(!$exe->setXPStyleOff(), "drop a non existant XP manifest");
ok($exe->setXPStyleOn('Test'), "add a XP manifest");
ok($exe->setXPStyleOff(), "drop the XP manifest");
ok($exe->setXPStyleOn('Test'), "add a XP manifest");

ok($exe->updateResource(
	type => RCDATA, 
	name => 'foo', 
	data => 'foo...',
), "add a foo RCDATA");

ok($exe->updateResource(
	path => 'RCDATA/bar',
	data => 'bar...',
), "add a bar RCDATA");

# Force commit
#ok($exe->commit(), "force commit");

#FIXME
#ok($exe->deleteResource(
#	path => 'RT_RCDATA/foo', 
#), "delete a foo RCDATA");
