use Test2::V0;
use Test2::Require::AuthorTesting;

use Config;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use IPC::Run qw( run );

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $zuzudoc_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzudoc.pl' );
my $module_file = File::Spec->catfile(
	$repo_root,
	'stdlib',
	'modules',
	'std',
	'io.zzm',
);

ok -x $zuzudoc_bin, 'bin/zuzudoc.pl exists and is executable';

sub write_doc_file {
	my ( $path, $heading ) = @_;

	open my $fh, '>:encoding(UTF-8)', $path
		or die "Could not write $path: $!";
	print {$fh} <<"POD";
=pod

=head1 $heading

Generated test documentation.

=cut
POD
	close $fh or die "Could not close $path: $!";

	return $path;
}

sub run_zuzudoc {
	my ( $env, @args ) = @_;

	my $stdout = '';
	my $stderr = '';

	local %ENV = ( %ENV, %{ $env // {} }, PAGER => 'cat' );
	run [ $^X, $zuzudoc_bin, @args ],
		'<', \undef,
		'>', \$stdout,
		'2>', \$stderr;

	return {
		exit   => $? >> 8,
		output => $stdout . $stderr,
		stdout => $stdout,
		stderr => $stderr,
	};
}

my $module_result = run_zuzudoc(
	undef,
	"-I$repo_root/stdlib/modules",
	'std/io',
);
is $module_result->{exit}, 0,
	'zuzudoc.pl resolves module names via search paths';
like $module_result->{output}, qr/std\/io/,
	'zuzudoc.pl renders module pod text';

my $file_result = run_zuzudoc( undef, $module_file );
is $file_result->{exit}, 0, 'zuzudoc.pl accepts direct file paths';
like $file_result->{output}, qr/Filesystem paths and standard stream helpers/,
	'zuzudoc.pl renders named file documentation';

my $tmpdir = tempdir( CLEANUP => 1 );
my $path_dir = File::Spec->catdir( $tmpdir, 'bin' );
my $lib_dir = File::Spec->catdir( $tmpdir, 'modules' );
make_path( $path_dir, $lib_dir );

write_doc_file(
	File::Spec->catfile( $path_dir, 'parse_rdf.zzs' ),
	'PATH PARSE RDF',
);
write_doc_file(
	File::Spec->catfile( $path_dir, 'parse_rdf' ),
	'PATH PARSE RDF STEM',
);

my $path_env = {
	PATH => join(
		$Config::Config{path_sep} // ':',
		$path_dir,
		File::Spec->path,
	),
};

my $bin_result = run_zuzudoc( $path_env, '--bin', 'parse_rdf.zzs' );
is $bin_result->{exit}, 0,
	'zuzudoc.pl --bin resolves exact file names from PATH';
like $bin_result->{output}, qr/PATH PARSE RDF/,
	'zuzudoc.pl --bin renders documentation from PATH file';

my $fallback_result = run_zuzudoc( $path_env, 'parse_rdf.zzs' );
is $fallback_result->{exit}, 0,
	'zuzudoc.pl falls back to PATH when normal resolution fails';
like $fallback_result->{output}, qr/PATH PARSE RDF/,
	'zuzudoc.pl fallback renders documentation from PATH file';

write_doc_file(
	File::Spec->catfile( $lib_dir, 'parse_rdf.zzs' ),
	'MODULE PARSE RDF',
);

my $module_first_result = run_zuzudoc(
	$path_env,
	"-I$lib_dir",
	'parse_rdf',
);
is $module_first_result->{exit}, 0,
	'zuzudoc.pl keeps module resolution before PATH by default';
like $module_first_result->{output}, qr/MODULE PARSE RDF/,
	'zuzudoc.pl default precedence renders module documentation';
unlike $module_first_result->{output}, qr/PATH PARSE RDF/,
	'zuzudoc.pl default precedence does not render PATH documentation';

my $path_first_result = run_zuzudoc(
	$path_env,
	'--bin',
	"-I$lib_dir",
	'parse_rdf',
);
is $path_first_result->{exit}, 0,
	'zuzudoc.pl --bin resolves PATH before module candidates';
like $path_first_result->{output}, qr/PATH PARSE RDF STEM/,
	'zuzudoc.pl --bin precedence renders PATH documentation';
unlike $path_first_result->{output}, qr/MODULE PARSE RDF/,
	'zuzudoc.pl --bin precedence does not render module documentation';

done_testing;
