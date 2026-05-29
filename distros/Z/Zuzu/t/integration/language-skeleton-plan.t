use Test2::V0;
use Test2::Require::AuthorTesting;

use File::Spec;
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $zuzu_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzu.pl' );

my @cases = (
	{
		name => '-d0 keeps assert disabled',
		args => [ '-d0', '-e', 'assert false; say "after";' ],
		exit => 0,
		stdout => "after\n",
		stderr => '',
	},
	{
		name => '-d1 enables assert failure',
		args => [ '-d1', '-e', 'assert false; say "after";' ],
		exit => 255,
		stdout => '',
		stderr_like => qr/\AAssertion failed\n\z/,
	},
	{
		name => '-d3 prints debug at matching level',
		args => [ '-d3', '-e', 'debug 3, "shown"; say "visible";' ],
		exit => 0,
		stdout => "visible\n",
		stderr => "shown\n",
	},
	{
		name => 'warn writes to stderr',
		args => [ '-e', 'warn "careful"; say "visible";' ],
		exit => 0,
		stdout => "visible\n",
		stderr => "careful\n",
	},
	{
		name => '-d2 suppresses higher debug level without evaluating message',
		args => [
			'-d2',
			'-e',
			join ' ',
				'function explode () {',
				'die "debug should not evaluate";',
				'}',
				'debug 3, explode();',
				'say "visible";',
		],
		exit => 0,
		stdout => "visible\n",
		stderr => '',
	},
);

for my $case ( @cases ) {
	subtest $case->{name} => sub {
		my $result = _run_zuzu( @{ $case->{args} } );

		is $result->{exit}, $case->{exit}, 'exit status';
		is $result->{stdout}, $case->{stdout}, 'stdout';

		if ( exists $case->{stderr_like} ) {
			like $result->{stderr}, $case->{stderr_like}, 'stderr';
		}
		else {
			is $result->{stderr}, $case->{stderr}, 'stderr';
		}
	};
}

done_testing;

sub _run_zuzu {
	my @args = @_;

	my $stderr = gensym;
	my $pid = open3( undef, my $stdout, $stderr, $^X, $zuzu_bin, @args );
	my $out = do {
		local $/;
		<$stdout> // '';
	};
	my $err = do {
		local $/;
		<$stderr> // '';
	};
	waitpid $pid, 0;

	return {
		exit => $? >> 8,
		stdout => $out,
		stderr => $err,
	};
}
