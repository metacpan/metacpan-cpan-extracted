use strict;
use warnings;

use Test::Tester;	# must be loaded before Test::Builder
use Test::Most;
use FindBin;
use File::Spec;
use Test::NoShadow qw(shadowed_ok);

my $checkouts = File::Spec->catdir($FindBin::Bin, 'data', 'checkouts');
my $clean = File::Spec->catdir($FindBin::Bin, 'data', 'clean');

subtest 'shadowed_ok fails when packages are shadowed' => sub {
	my ($premature, @results) = run_tests(sub { shadowed_ok($checkouts) });

	is($premature, '', 'no premature output');
	is(scalar(@results), 1, 'one test was run');
	is($results[0]{ok}, 0, 'it failed');

	my $diag = $results[0]{diag} || '';
	like($diag, qr/Acme::Widget is provided by 3 files:/, 'names the package and the number of providers');
	foreach my $repo (qw(RepoA RepoB RepoC)) {
		like($diag, qr/\Q$repo\E/, "names $repo as a provider");
	}
	unlike($diag, qr/Acme::OnlyA/, 'does not name unique packages');
};

subtest 'shadowed_ok passes on a clean tree' => sub {
	my ($premature, @results) = run_tests(sub { shadowed_ok($clean) });

	is(scalar(@results), 1, 'one test was run');
	is($results[0]{ok}, 1, 'it passed');
	is($results[0]{diag}, '', 'no diagnostics');
};

subtest 'shadowed_ok honours the ignore option' => sub {
	my ($premature, @results) = run_tests(sub {
		shadowed_ok($checkouts, { ignore => [qr{/t/lib/Acme/Dup\.pm$}, qr{^Repo[BC]}] });
	});

	is($results[0]{ok}, 1, 'ignoring the shadowing providers leaves no shadows');
};

done_testing();
