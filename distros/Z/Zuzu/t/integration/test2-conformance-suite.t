use Test2::V0;

use JSON::PP qw( decode_json );
use File::Spec;
use Scalar::Util qw( blessed );

use Zuzu::Parser;
use Zuzu::Runtime;

sub slurp_utf8 {
	my ( $path ) = @_;

	open my $fh, '<:encoding(UTF-8)', $path
		or die "Cannot read $path: $!";
	local $/;
	my $text = <$fh>;
	close $fh;

	return $text;
}

my $PARSER = Zuzu::Parser->new;

sub parse_case {
	my ( $case ) = @_;
	return $PARSER->parse( $case->{source}, $case->{file} );
}

sub runtime_for_case {
	my ( $case ) = @_;
	my %runtime = %{ $case->{runtime} // {} };
	return Zuzu::Runtime->new(%runtime);
}

sub assert_error {
	my ( $case, $error ) = @_;

	ok( blessed($error), "$case->{id}: failed with structured error object" );

	my $expected_class = $case->{error_kind} eq 'compile'
		? 'Zuzu::Error::Compile'
		: 'Zuzu::Error::Runtime';
	ok(
		blessed($error) and $error->isa($expected_class),
		"$case->{id}: error kind is $case->{error_kind}",
	);
	is( $error->code, $case->{error_code}, "$case->{id}: error code matches fixture" );
	is( $error->message, $case->{error_message}, "$case->{id}: error message matches fixture" );
	is( $error->file, $case->{file}, "$case->{id}: source file metadata matches fixture" );
}

my $fixture_path = File::Spec->catfile(
	't', 'fixtures', 'semantics', 'conformance-suite.json',
);
my $fixture_doc = decode_json( slurp_utf8($fixture_path) );
my @cases = @{ $fixture_doc->{cases} // [] };

ok( scalar @cases > 0, 'loaded conformance fixtures' );

my @groups = qw( syntax semantics runtime errors );
for my $group ( @groups ) {
	my @group_cases = grep { $_->{group} eq $group } @cases;

	subtest "conformance group: $group" => sub {
		ok( scalar @group_cases > 0, "group '$group' has fixtures" );

		for my $case ( sort { $a->{id} cmp $b->{id} } @group_cases ) {
			my $mode = $case->{mode};

			if ( $mode eq 'result' ) {
				my $runtime = runtime_for_case($case);
				my $ast = parse_case($case);
				$runtime->evaluate($ast);

				my $entrypoint = $case->{entrypoint} // '__fixture_result';
				is(
					$runtime->call($entrypoint),
					$case->{expected},
					"$case->{id}: returned expected result",
				);
				next;
			}

			if ( $mode eq 'parse_error' ) {
				my $error = dies {
					parse_case($case);
				};
				assert_error( $case, $error );
				next;
			}

			if ( $mode eq 'evaluate_error' ) {
				my $ast = parse_case($case);
				my $runtime = runtime_for_case($case);
				my $error = dies {
					$runtime->evaluate($ast);
				};
				assert_error( $case, $error );
				next;
			}

			if ( $mode eq 'call_error' ) {
				my $ast = parse_case($case);
				my $runtime = runtime_for_case($case);
				$runtime->evaluate($ast);

				my $entrypoint = $case->{entrypoint} // '__fixture_run';
				my $error = dies {
					$runtime->call($entrypoint);
				};
				assert_error( $case, $error );
				next;
			}

			fail "$case->{id}: unsupported fixture mode '$mode'";
		}
	};
}

done_testing;
