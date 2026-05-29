use Test2::V0;

use Config;
use File::Basename qw( dirname );
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use IPC::Run qw( run );
use JSON::PP;

my $repo_root = File::Spec->rel2abs( File::Spec->curdir );
my $zuzu_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzu.pl' );
my $zuzuzoo_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzuzoo.pl' );

sub run_zuzuzoo {
	my ( $home, @args ) = @_;

	my @cmd = ( $zuzuzoo_bin, @args );
	my ( $stdout, $stderr ) = ( '', '' );

	local $ENV{HOME} = $home;
	local $ENV{PATH} = File::Spec->catdir( $repo_root, 'bin' )
		. $Config::Config{path_sep} . $ENV{PATH};
	local $ENV{ZUZU_COMMAND} = $zuzu_bin;
	run \@cmd, '<', \undef, '>', \$stdout, '2>', \$stderr;

	return {
		exit   => $? >> 8,
		stdout => $stdout,
		stderr => $stderr,
		output => $stdout . $stderr,
	};
}

sub make_dist_tar {
	my ( $tmp ) = @_;

	my $root = File::Spec->catdir( $tmp, 'hardening-app-1.0.0' );
	my $module_path = File::Spec->catfile(
		$root,
		'modules',
		'hardening',
		'app.zzm',
	);
	my $meta_path = File::Spec->catfile( $root, 'zuzu-distribution.json' );
	make_path( dirname($module_path) );

	open my $module_fh, '>:encoding(UTF-8)', $module_path
		or die "Could not create $module_path: $!";
	print {$module_fh} "// hardening\n";
	close $module_fh;

	open my $meta_fh, '>:encoding(UTF-8)', $meta_path
		or die "Could not create $meta_path: $!";
	print {$meta_fh} <<'JSON';
{
	"name": "hardening-app",
	"version": "1.0.0",
	"author": "Example",
	"license": "MIT"
}
JSON
	close $meta_fh;

	my $tarball = File::Spec->catfile( $tmp, 'hardening-app-1.0.0.tar' );
	system( 'tar', '-cf', $tarball, '-C', $tmp, 'hardening-app-1.0.0' ) == 0
		or die "Could not create tarball $tarball";

	return $tarball;
}

my $tmp = tempdir( CLEANUP => 1 );
my $tarball = make_dist_tar($tmp);

my $lock_home = File::Spec->catdir( $tmp, 'home-lock' );
my $meta_dir = File::Spec->catdir( $lock_home, '.zuzu', 'meta' );
my $lock_dir = File::Spec->catdir( $meta_dir, '.zuzuzoo.lock' );
make_path($lock_dir);
open my $owner_fh, '>:encoding(UTF-8)',
	File::Spec->catfile( $lock_dir, 'owner.json' )
	or die "Could not create owner.json: $!";
print {$owner_fh} JSON::PP->new->canonical->encode(
	{
		pid        => 4242,
		operation  => 'install',
		meta_dir   => $meta_dir,
		created_at => '2026-05-08T00:00:00Z',
	},
);
close $owner_fh;

my $locked = run_zuzuzoo(
	$lock_home,
	'install',
	'--no-test',
	'--lock-timeout',
	'0.1',
	$tarball,
);
is $locked->{exit}, 1, 'held install lock fails clearly after timeout';
like $locked->{stderr}, qr/Timed out waiting for Zuzuzoo lock/,
	'lock timeout names the lock';
like $locked->{stderr}, qr/"pid":4242/,
	'lock timeout includes readable owner metadata';

my $corrupt_home = File::Spec->catdir( $tmp, 'home-corrupt' );
make_path($corrupt_home);
my $corrupt = File::Spec->catfile( $tmp, 'not-an-archive.tar' );
open my $bad_fh, '>:raw', $corrupt
	or die "Could not create corrupt archive: $!";
print {$bad_fh} "not an archive";
close $bad_fh;

my $bad = run_zuzuzoo( $corrupt_home, 'install', '--no-test', $corrupt );
is $bad->{exit}, 1, 'corrupt archive install fails';
like $bad->{stderr}, qr/Corrupt source archive/,
	'corrupt archive diagnostic is explicit';
like $bad->{stderr}, qr/source_type=file/,
	'corrupt archive diagnostic includes source type';
like $bad->{stderr}, qr/path=\Q$corrupt\E/,
	'corrupt archive diagnostic includes source path';

done_testing;
