use v5.40;
use Test2::V1 -ipP;
use Path::Tiny qw(path cwd);
use File::Spec;
use IPC::Open3;
use Symbol qw(gensym);

################################################################################
# This tests whether bin/thunderhorse script works
################################################################################

my $bin = path('bin/thunderhorse')->absolute;
my $orig_dir = cwd->absolute;
my $tempdir;

sub run_command (@cmd)
{
	my $pid = open3(my $stdin, my $stdout, my $stderr = gensym, @cmd);
	close $stdin;

	my $out = do { local $/; readline $stdout };
	my $err = do { local $/; readline $stderr };

	waitpid($pid, 0);
	my $exit = $? >> 8;

	return ($exit, $out, $err);
}

subtest 'should generate an app from full-app example' => sub {
	$tempdir = Path::Tiny->tempdir();
	chdir $tempdir;

	my ($exit) = run_command($^X, $bin, '-g', 'full-app', 'Test::App');

	is $exit, 0, 'exit code ok';

	ok path('lib/Test/App.pm')->exists, 'Test/App.pm created';
	ok path('lib/Test/App/Controller/API.pm')->exists, 'Test::App controller created';
	ok path('app.pl')->exists, 'app.pl created';
	ok path('conf/config.pl')->exists, 'config created';
	ok path('t/base.t')->exists, 'test created';

	my $app_content = path('lib/Test/App.pm')->slurp;
	like $app_content, qr{^package Test::App;$}m, 'namespace replaced';
	unlike $app_content, qr{FullApp}, 'old namespace removed';

	my $app_pl_content = path('app.pl')->slurp;
	like $app_pl_content, qr{^use Test::App;$}m, 'app.pl uses correct namespace';
	like $app_pl_content, qr{^Test::App->new}m, 'app.pl instantiates correct class';

	chdir $orig_dir;
};

subtest 'should generate an app with tabs when requested' => sub {
	$tempdir = Path::Tiny->tempdir();
	chdir $tempdir;

	my ($exit) = run_command($^X, $bin, '-g', 'full-app', '--tabs', 'TestApp');

	is $exit, 0, 'exit code ok';
	my $app_content = path('lib/TestApp.pm')->slurp;
	like $app_content, qr{\t}, 'tabs present';

	chdir $orig_dir;
};

subtest 'should dump configuration' => sub {
	$tempdir = Path::Tiny->tempdir();
	chdir $tempdir;

	run_command($^X, $bin, '-g', 'full-app', 'TestApp');

	my ($exit, $out, $err) = run_command($^X, $bin, '-c', 'app.pl');

	is $exit, 0, 'exit code ok';
	my $output = $out . $err;
	like $output, qr{^\%config\s*=}, 'dumper output present';
	like $output, qr{'controllers'\s*=>}, 'config key present';

	chdir $orig_dir;
};

subtest 'should dump routes' => sub {
	$tempdir = Path::Tiny->tempdir();
	chdir $tempdir;

	run_command($^X, $bin, '-g', 'full-app', 'TestApp');

	my ($exit, $out, $err) = run_command($^X, $bin, '-l', 'app.pl');

	is $exit, 0, 'exit code ok';
	my $output = $out . $err;
	like $output, qr{^\@locations\s*=}, 'dumper output present';
	like $output, qr{'pattern'}, 'pattern info present';
	like $output, qr{'name'}, 'location structure present';
	like $output, qr{'controller'}, 'controller info present';

	chdir $orig_dir;
};

subtest 'should pass tests of generated app' => sub {
	$tempdir = Path::Tiny->tempdir();
	chdir $tempdir;

	run_command($^X, $bin, '-g', 'full-app', 'TestApp');

	my ($exit) = run_command($^X, '-Ilib', 't/base.t');

	is $exit, 0, 'test exit code ok';

	chdir $orig_dir;
};

subtest 'should generate controllers example' => sub {
	$tempdir = Path::Tiny->tempdir();
	chdir $tempdir;

	my ($exit) = run_command($^X, $bin, '-g', 'controllers', 'MyControllerApp');

	is $exit, 0, 'exit code ok';
	ok path('lib/MyControllerApp.pm')->exists, 'MyControllerApp.pm created';
	ok path('lib/MyControllerApp/Controller/Clock.pm')->exists, 'controller created';

	my $app_content = path('lib/MyControllerApp.pm')->slurp;
	like $app_content, qr{package MyControllerApp}, 'namespace replaced';
	unlike $app_content, qr{\bControllerApp}, 'old namespace removed';

	chdir $orig_dir;
};

subtest 'should generate hello-world example' => sub {
	$tempdir = Path::Tiny->tempdir();
	chdir $tempdir;

	my ($exit) = run_command($^X, $bin, '-g', 'hello-world', 'HelloTest');

	is $exit, 0, 'exit code ok';
	ok path('app.pl')->exists, 'app.pl created';

	my $app_content = path('app.pl')->slurp;
	like $app_content, qr{package HelloTest}, 'namespace replaced';
	unlike $app_content, qr{HelloApp}, 'old namespace removed';

	chdir $orig_dir;
};

subtest 'should fail without target' => sub {
	my ($exit) = run_command($^X, $bin, '-g', 'full-app');

	isnt $exit, 0, 'exit code indicates failure';
};

subtest 'should show help with -h flag' => sub {
	my ($exit, $out, $err) = run_command($^X, $bin, '-h');

	is $exit, 0, 'exit code ok';
	my $output = $out . $err;
	like $output, qr{\Qthunderhorse [OPTIONS] TARGET\E}, 'help text present';
};

done_testing;

