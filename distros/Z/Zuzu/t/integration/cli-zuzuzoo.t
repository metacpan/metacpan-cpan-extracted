use Test2::V0;
use Test2::Require::AuthorTesting;

use Config;
use File::Basename qw( dirname );
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use IPC::Run qw( run );
use JSON::PP;

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $zuzu_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzu.pl' );
my $zuzuzoo_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzuzoo.pl' );

ok -x $zuzu_bin, 'bin/zuzu.pl exists and is executable';
ok -x $zuzuzoo_bin, 'bin/zuzuzoo.pl exists and is executable';

sub run_zuzuzoo {
	my ( $home, $stdin, @args ) = @_;

	my @cmd = ( $zuzuzoo_bin, @args );
	my ( $stdout, $stderr ) = ( '', '' );
	$stdin = '' if ! defined $stdin;

	local $ENV{HOME} = $home;
	local $ENV{PATH} = File::Spec->catdir( $repo_root, 'bin' )
		. $Config::Config{path_sep} . $ENV{PATH};
	local $ENV{ZUZU_COMMAND} = $zuzu_bin;
	run \@cmd, '<', \$stdin, '>', \$stdout, '2>', \$stderr;

	return {
		exit   => $? >> 8,
		stdout => $stdout,
		stderr => $stderr,
		output => $stdout . $stderr,
	};
}

sub make_dist_tar {
	my ( %args ) = @_;

	my $tmp = $args{tmp};
	my $name = $args{name};
	my $version = $args{version} // '1.0.0';
	my $module = $args{module};
	my $root_name = "$name-$version";
	my $dist_root = File::Spec->catdir( $tmp, $root_name );
	my $module_path = File::Spec->catfile(
		$dist_root,
		'modules',
		split m{/}, "$module.zzm",
	);
	my $meta_path = File::Spec->catfile(
		$dist_root,
		'zuzu-distribution.json',
	);

	make_path( dirname($module_path) );

	open my $mod_fh, '>:encoding(UTF-8)', $module_path
		or die "Could not create $module_path: $!";
	print {$mod_fh} <<"ZZM";
function version () {
\treturn "$version";
}
ZZM
	close $mod_fh;

	open my $meta_fh, '>:encoding(UTF-8)', $meta_path
		or die "Could not create $meta_path: $!";
	print {$meta_fh} <<"JSON";
{
	"name": "$name",
	"version": "$version",
	"author": "Example Author",
	"license": "CC0-1.0"
}
JSON
	close $meta_fh;

	my $tarball = File::Spec->catfile( $tmp, "$root_name.tar" );
	system( 'tar', '-cf', $tarball, '-C', $tmp, $root_name ) == 0
		or die "Could not create tarball $tarball";

	return $tarball;
}

sub installed_meta_path {
	my ( $home, $name, $version ) = @_;
	return File::Spec->catfile(
		$home,
		'.zuzu',
		'meta',
		"$name-$version.json",
	);
}

sub installed_module_path {
	my ( $home, $module ) = @_;
	return File::Spec->catfile(
		$home,
		'.zuzu',
		'modules',
		split m{/}, "$module.zzm",
	);
}

sub decode_json_output {
	my ( $text ) = @_;
	return JSON::PP->new->decode($text);
}

my $tmp = tempdir( CLEANUP => 1 );
my $tar_one = make_dist_tar(
	tmp     => $tmp,
	name    => 'phase-seven-one',
	version => '1.0.0',
	module  => 'phase7/one',
);
my $tar_two = make_dist_tar(
	tmp     => $tmp,
	name    => 'phase-seven-two',
	version => '1.0.0',
	module  => 'phase7/two',
);

my $usage_home = File::Spec->catdir( $tmp, 'home-usage' );
make_path($usage_home);

my $help = run_zuzuzoo( $usage_home, undef, '--help' );
is $help->{exit}, 0, '--help exits successfully';
like $help->{stdout}, qr/Usage:/, '--help prints usage';

my $usage_error = run_zuzuzoo( $usage_home, undef );
is $usage_error->{exit}, 2, 'missing command is a usage error';
like $usage_error->{stderr}, qr/Usage:/, 'usage error prints usage';

my $unknown = run_zuzuzoo( $usage_home, undef, 'bogus-command' );
is $unknown->{exit}, 2, 'unknown command exits with usage status';
like $unknown->{stderr}, qr/Unknown command: bogus-command/,
	'unknown command is reported';

my $bad_version = run_zuzuzoo( $usage_home, undef, '--version' );
is $bad_version->{exit}, 2, '--version is rejected with usage status';
like $bad_version->{stderr}, qr/--version is not supported/,
	'--version rejection is explicit';

my $dry_home = File::Spec->catdir( $tmp, 'home-dry-install' );
make_path($dry_home);
my $dry_install = run_zuzuzoo(
	$dry_home,
	undef,
	'install',
	'--dry-run',
	$tar_one,
	$tar_two,
);
is $dry_install->{exit}, 0, 'multi-target install dry-run succeeds';
like $dry_install->{stdout}, qr/phase-seven-one 1\.0\.0/,
	'install dry-run plans first target';
like $dry_install->{stdout}, qr/phase-seven-two 1\.0\.0/,
	'install dry-run plans second target';
like $dry_install->{stdout}, qr/Dry run complete/,
	'install dry-run reports completion';
like $dry_install->{stderr}, qr/zuzuzoo: planning install for/,
	'install reports progress to stderr by default';
like $dry_install->{stderr}, qr/zuzuzoo: using local archive/,
	'install progress names local archive source';
ok !-e installed_meta_path( $dry_home, 'phase-seven-one', '1.0.0' ),
	'install dry-run does not write metadata';

my $quiet_install = run_zuzuzoo(
	$dry_home,
	undef,
	'install',
	'--quiet',
	'--dry-run',
	$tar_one,
);
is $quiet_install->{exit}, 0, 'quiet install dry-run succeeds';
unlike $quiet_install->{stderr}, qr/zuzuzoo: planning install for/,
	'--quiet suppresses install progress';

my $home = File::Spec->catdir( $tmp, 'home-main' );
make_path($home);
my $install = run_zuzuzoo( $home, undef, '--no-test', $tar_one, $tar_two );
is $install->{exit}, 0, 'implicit multi-target install succeeds';
like $install->{stdout}, qr/Install complete/, 'install reports completion';

my $meta_one = installed_meta_path( $home, 'phase-seven-one', '1.0.0' );
my $meta_two = installed_meta_path( $home, 'phase-seven-two', '1.0.0' );
my $module_one = installed_module_path( $home, 'phase7/one' );
my $module_two = installed_module_path( $home, 'phase7/two' );
ok -f $meta_one, 'first distribution metadata installed';
ok -f $meta_two, 'second distribution metadata installed';
ok -f $module_one, 'first module installed';
ok -f $module_two, 'second module installed';

my $list = run_zuzuzoo( $home, undef, 'list' );
is $list->{exit}, 0, 'list succeeds';
like $list->{stdout}, qr/phase-seven-one\t1\.0\.0\t\Q$meta_one\E/,
	'list prints name, version, and metadata path';

my $list_json = run_zuzuzoo( $home, undef, 'list', '--json' );
is $list_json->{exit}, 0, 'list --json succeeds';
my $listed = decode_json_output( $list_json->{stdout} );
is scalar(@$listed), 2, 'list --json returns installed distributions';

my $query = run_zuzuzoo( $home, undef, 'query', 'phase7/one' );
is $query->{exit}, 0, 'query by module succeeds';
like $query->{stdout}, qr/^\{\n/, 'query pretty-prints JSON';
like $query->{stdout}, qr/"name"\s*:\s*"phase-seven-one"/,
	'query JSON includes distribution name';

my $missing_query = run_zuzuzoo( $home, undef, 'query', 'missing/module' );
is $missing_query->{exit}, 1, 'missing query exits with operation failure';

my $query_dist = run_zuzuzoo(
	$home,
	undef,
	'query',
	'--dist',
	'phase-seven-one',
);
is $query_dist->{exit}, 0, 'query --dist dispatch succeeds';
like $query_dist->{stdout}, qr/"name"\s*:\s*"phase-seven-one"/,
	'query --dist returns distribution JSON';

my $verify_dist = run_zuzuzoo(
	$home,
	undef,
	'verify',
	'--dist',
	'phase-seven-one',
);
is $verify_dist->{exit}, 0, 'verify --dist dispatch succeeds';
like $verify_dist->{stdout}, qr/Verification ok/,
	'verify --dist reports success';

my $remove_dist_dry = run_zuzuzoo(
	$home,
	undef,
	'remove',
	'--dist',
	'--dry-run',
	'phase-seven-one',
);
is $remove_dist_dry->{exit}, 0, 'remove --dist dry-run dispatch succeeds';
like $remove_dist_dry->{stdout}, qr/phase-seven-one 1\.0\.0/,
	'remove --dist dry-run includes distribution';
like $remove_dist_dry->{stdout}, qr/Dry run complete/,
	'remove --dist dry-run reports completion';
ok -f $meta_one, 'remove --dist dry-run leaves metadata in place';

my $remove_multi_dry = run_zuzuzoo(
	$home,
	undef,
	'remove',
	'--dry-run',
	'phase7/one',
	'phase7/two',
);
is $remove_multi_dry->{exit}, 0, 'multi-target remove dry-run succeeds';
like $remove_multi_dry->{stdout}, qr/phase-seven-one 1\.0\.0/,
	'remove dry-run plans first module target';
like $remove_multi_dry->{stdout}, qr/phase-seven-two 1\.0\.0/,
	'remove dry-run plans second module target';

unlink $module_one or die "Could not remove $module_one: $!";
my $verify_missing = run_zuzuzoo( $home, undef, 'verify', 'phase7/one' );
is $verify_missing->{exit}, 3, 'verify failure exits with code 3';
like $verify_missing->{stdout}, qr/Verification failed/,
	'verify failure is summarized';
like $verify_missing->{stdout}, qr/Missing files: 1/,
	'verify reports missing file count';

my $decline_home = File::Spec->catdir( $tmp, 'home-decline' );
make_path($decline_home);
run_zuzuzoo( $decline_home, undef, '--no-test', $tar_one );
my $decline_meta = installed_meta_path(
	$decline_home,
	'phase-seven-one',
	'1.0.0',
);
my $declined = run_zuzuzoo(
	$decline_home,
	"n\n",
	'remove',
	'--dist',
	'phase-seven-one',
);
is $declined->{exit}, 4, 'declined remove exits with code 4';
like $declined->{stdout}, qr/Remove declined/,
	'declined remove is reported';
ok -f $decline_meta, 'declined remove leaves metadata in place';

my $yes_home = File::Spec->catdir( $tmp, 'home-yes' );
make_path($yes_home);
run_zuzuzoo( $yes_home, undef, '--no-test', $tar_one );
my $yes_meta = installed_meta_path( $yes_home, 'phase-seven-one', '1.0.0' );
ok -f $yes_meta, 'yes-remove fixture is installed';
my $yes_remove = run_zuzuzoo(
	$yes_home,
	undef,
	'remove',
	'--dist',
	'--yes',
	'phase-seven-one',
);
is $yes_remove->{exit}, 0, '--yes remove succeeds';
like $yes_remove->{stdout}, qr/Remove complete/,
	'--yes remove reports completion';
ok !-e $yes_meta, '--yes remove deletes metadata';

done_testing;
