use utf8;
use strict;
use warnings;

use Test2::V0;
use File::Spec;
use File::Temp qw( tempdir );
use IPC::Run qw( run );

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $dispatcher = File::Spec->catfile( $repo_root, 'bin', 'zuzu' );

ok -x $dispatcher, 'bin/zuzu exists and is executable';

sub write_interpreter {
	my ( $dir, $name, $label ) = @_;
	my $path = File::Spec->catfile( $dir, $name );

	open my $fh, '>:encoding(UTF-8)', $path
		or die "Could not write $path: $!";
	print {$fh} <<"SH";
#!/bin/sh
printf 'interpreter=%s\\n' '$label'
printf 'ZUZU=%s\\n' "\${ZUZU-}"
printf 'args=%s\\n' "\$*"
SH
	close $fh or die "Could not close $path: $!";
	chmod 0755, $path or die "Could not chmod $path: $!";

	return $path;
}

sub run_dispatcher {
	my ( $path, $zuzu ) = @_;
	my $stdout = '';
	my $stderr = '';

	local %ENV = ( PATH => $path );
	$ENV{ZUZU} = $zuzu if defined $zuzu;

	run [ $dispatcher, 'alpha', 'beta' ], '<', \undef, '>', \$stdout, '2>', \$stderr;

	return {
		exit   => $? >> 8,
		stdout => $stdout,
		stderr => $stderr,
	};
}

{
	my $dir = tempdir( CLEANUP => 1 );
	write_interpreter( $dir, 'zuzu-rust', 'rust' );
	write_interpreter( $dir, 'zuzu.pl',   'perl' );
	write_interpreter( $dir, 'zuzu-js',   'js' );

	my $result = run_dispatcher($dir);

	is $result->{exit}, 0, 'default dispatcher exits successfully';
	like $result->{stdout}, qr/^interpreter=rust$/m,
		'default dispatcher prefers zuzu-rust';
	like $result->{stdout}, qr/^ZUZU=zuzu-rust$/m,
		'default dispatcher exports selected interpreter';
	like $result->{stdout}, qr/^args=alpha beta$/m,
		'default dispatcher passes command arguments';
	is $result->{stderr}, '', 'default dispatcher does not write stderr';
}

{
	my $dir = tempdir( CLEANUP => 1 );
	write_interpreter( $dir, 'zuzu.pl', 'perl' );
	write_interpreter( $dir, 'zuzu-js', 'js' );

	my $result = run_dispatcher($dir);

	is $result->{exit}, 0, 'fallback dispatcher exits successfully';
	like $result->{stdout}, qr/^interpreter=perl$/m,
		'default dispatcher falls back to zuzu.pl before zuzu-js';
	like $result->{stdout}, qr/^ZUZU=zuzu\.pl$/m,
		'fallback dispatcher exports zuzu.pl';
}

{
	my $dir = tempdir( CLEANUP => 1 );
	write_interpreter( $dir, 'zuzu-rust', 'rust' );
	write_interpreter( $dir, 'custom-zuzu', 'custom' );

	my $result = run_dispatcher( $dir, 'custom-zuzu' );

	is $result->{exit}, 0, 'custom ZUZU dispatcher exits successfully';
	like $result->{stdout}, qr/^interpreter=custom$/m,
		'custom ZUZU value overrides default interpreter preference';
	like $result->{stdout}, qr/^ZUZU=custom-zuzu$/m,
		'custom ZUZU value is visible to the selected interpreter';
}

{
	my $dir = tempdir( CLEANUP => 1 );
	my $custom_dir = File::Spec->catdir( $dir, 'custom bin' );
	mkdir $custom_dir or die "Could not create $custom_dir: $!";
	my $custom = write_interpreter(
		$custom_dir,
		'custom-zuzu',
		'custom absolute',
	);
	write_interpreter( $dir, 'zuzu-rust', 'rust' );

	my $result = run_dispatcher( $dir, $custom );

	is $result->{exit}, 0, 'absolute custom ZUZU dispatcher exits successfully';
	like $result->{stdout}, qr/^interpreter=custom absolute$/m,
		'absolute custom ZUZU value overrides default interpreter preference';
	like $result->{stdout}, qr/^\QZUZU=$custom\E$/m,
		'absolute custom ZUZU value is preserved for the selected interpreter';
}

done_testing;
