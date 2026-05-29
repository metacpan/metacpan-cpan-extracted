use Test2::V0;

use File::Find qw( find );
use File::Spec;
use IPC::Run qw( run );
use TAP::Parser;

use Zuzu::Parser;
use Zuzu::Test::ZPathFacelessPortDiagnostics qw(
	format_summary_lines
	summarize_failed_queries
);

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my @ztests_dirs = (
	File::Spec->catdir( $repo_root, 'languagetests' ),
	File::Spec->catdir( $repo_root, 'stdlib', 'tests' ),
);
my @runtime_lib = (
	File::Spec->catdir( $repo_root, 't', 'modules' ),
	File::Spec->catdir( $repo_root, 'stdlib', 'test-modules' ),
	File::Spec->catdir( $repo_root, 'stdlib', 'modules' ),
);
my $zuzu_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzu.pl' );
my $fixture_dir = File::Spec->catdir( $repo_root, 'stdlib', 'test-fixtures' );

my @zzs_files;
find(
	{
		no_chdir => 1,
		wanted => sub {
			return if -d $_;
			return if $_ !~ /\.zzs\z/;
			push @zzs_files, $File::Find::name;
		},
	},
	grep { -d $_ } @ztests_dirs,
);
@zzs_files = sort @zzs_files;

ok scalar @zzs_files > 0, 'found at least one ztest script';

my $parser = Zuzu::Parser->new;

for my $ztest_path ( @zzs_files ) {
	my $display_name = File::Spec->abs2rel( $ztest_path, $repo_root );

	subtest $display_name => sub {
		if ( $display_name eq 'stdlib/tests/javascript.zzs' ) {
			plan skip_all => 'Perl runtime does not support the javascript module';
		}

		my $source = _slurp_utf8( $ztest_path );
		ok defined $source, 'loaded ztest source';

		my $ast = eval { $parser->parse( $source, $ztest_path ) };
		if ( not defined $ast ) {
			fail 'parsed ztest source';
			diag $@;
			return;
		}
		pass 'parsed ztest source';

		my $run = _run_ztest_cli($ztest_path);

		if ( not $run->{ok} ) {
			fail 'executed ztest script';
			if ( defined $run->{error} and $run->{error} ne '' ) {
				diag $run->{error};
			}
			if ( length $run->{stderr} ) {
				diag "stderr from $display_name:";
				diag $run->{stderr};
			}
			_emit_faceless_port_diagnostics(
				$display_name,
				{
					failed_queries =>
						_failed_queries_from_tap_text( $run->{stdout} ),
				},
			);
			return;
		}
		pass 'executed ztest script';

		if ( length $run->{stderr} ) {
			note "stderr from $display_name:";
			note $run->{stderr};
		}

		my $tap_summary = _assert_valid_tap( $display_name, $run->{stdout} );
		_emit_faceless_port_diagnostics( $display_name, $tap_summary );
	};
}

sub _run_ztest_cli {
	my ( $ztest_path ) = @_;

	my @cmd = (
		$^X,
		$zuzu_bin,
		( map { ( '-I', $_ ) } @runtime_lib ),
		$ztest_path,
	);
	my $stdout = '';
	my $stderr = '';
	my $ran = eval {
		local $ENV{ZUZU} = $zuzu_bin;
		local $ENV{FIXTURE_DIR} = $fixture_dir;
		run( \@cmd, '<', \undef, '>', \$stdout, '2>', \$stderr );
		1;
	};
	my $status = $?;
	my $error = '';
	if ( not $ran ) {
		$error = "Could not run ztest script: $@";
	}
	elsif ( $status != 0 ) {
		my $exit_code = $status >> 8;
		my $signal = $status & 127;
		$error = "ztest script exited with status $exit_code";
		$error .= " after signal $signal" if $signal;
	}

	return {
		ok => $ran && $status == 0 ? 1 : 0,
		stdout => $stdout,
		stderr => $stderr,
		error => $error,
		status => $status,
	};
}

sub _assert_valid_tap {
	my ( $display_name, $tap_out ) = @_;

	if ( not defined $tap_out or $tap_out eq '' ) {
		fail 'ztest produced TAP tests';
		fail 'ztest TAP plan is valid';
		fail 'ztest TAP stream has no parser problems';
		return {
			tests_seen => 0,
			failed_queries => [],
			has_problems => 1,
			skip_all => 0,
		};
	}

	my $tap_parser = TAP::Parser->new( { source => \$tap_out } );
	my $tests_seen = 0;
	my $skip_all = 0;
	my $skip_reason = '';
	my @failed_queries;

	while ( my $result = $tap_parser->next ) {
		if ( $result->is_test ) {
			$tests_seen++;
			my $desc = $result->description;
			$desc = "test " . $result->number if not defined $desc or $desc eq '';
			ok $result->is_ok, $desc;
			if ( not $result->is_ok and $desc =~ /\AQuery:\s*(.+)\z/ ) {
				push @failed_queries, $1;
			}
		}
		elsif ( $result->is_comment ) {
			if ( $result->as_string =~ /\A#\s*SKIP:\s*(.*)\z/ ) {
				$skip_reason = $1;
			}
			note $result->as_string;
		}
		elsif ( $result->is_plan ) {
			if (
				$result->can('tests_planned')
				and $result->tests_planned == 0
				and $result->can('directive')
				and defined $result->directive
				and $result->directive eq 'SKIP'
			) {
				$skip_all = 1;
				if (
					$skip_reason eq ''
					and $result->can('explanation')
					and defined $result->explanation
				) {
					$skip_reason = $result->explanation;
				}
			}
		}
		elsif ( $result->is_bailout ) {
			BAIL_OUT( "ztest bailed out ($display_name): " . $result->as_string );
		}
	}

	if ( $tests_seen == 0 and $skip_all and $skip_reason ne '' ) {
		SKIP: {
			skip "ztest skipped: $skip_reason", 1;
		}
	}
	else {
		ok( $tests_seen > 0, 'ztest produced TAP tests' );
	}
	ok( $tap_parser->is_good_plan, 'ztest TAP plan is valid' );
	my $has_problems = $tap_parser->has_problems ? 1 : 0;
	ok( $has_problems == 0, 'ztest TAP stream has no parser problems' );

	return {
		tests_seen => $tests_seen,
		failed_queries => \@failed_queries,
		has_problems => $has_problems,
		skip_all => $skip_all,
	};
}

sub _emit_faceless_port_diagnostics {
	my ( $display_name, $tap_summary ) = @_;

	return if $display_name ne 'stdlib/tests/std/path/z.zzs';
	return if not defined $tap_summary;

	my $failed_queries = $tap_summary->{failed_queries};
	$failed_queries = [] if not defined $failed_queries;
	return if scalar @{ $failed_queries } == 0;

	diag 'zpath-faceless-port diagnostics:';
	diag 'failed query count: ' . scalar @{ $failed_queries };

	my $summary = summarize_failed_queries( $failed_queries );
	my $lines = format_summary_lines( $summary );
	for my $line ( @{ $lines } ) {
		diag '  ' . $line;
	}
}

sub _failed_queries_from_tap_text {
	my ( $tap_out ) = @_;

	return [] if not defined $tap_out or $tap_out eq '';

	my @failed_queries = ( $tap_out =~ /^not ok \d+ - Query:\s*(.+)$/mg );

	return \@failed_queries;
}

sub _slurp_utf8 {
	my ( $path ) = @_;

	open my $fh, '<:encoding(UTF-8)', $path
		or die "Could not open $path: $!";
	local $/;
	my $content = <$fh>;
	close $fh;

	return $content;
}

done_testing;
