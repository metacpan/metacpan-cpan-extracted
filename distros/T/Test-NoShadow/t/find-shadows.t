use strict;
use warnings;

use Test::Most;
use FindBin;
use File::Spec;
use Test::NoShadow qw(find_shadows);

my $checkouts = File::Spec->catdir($FindBin::Bin, 'data', 'checkouts');
my $clean = File::Spec->catdir($FindBin::Bin, 'data', 'clean');

subtest 'shadowed packages are returned' => sub {
	my $shadows = find_shadows($checkouts);

	is_deeply([sort keys %$shadows], [qw(Acme::Dup Acme::Widget)], 'only shadowed packages are returned');

	is(scalar(@{ $shadows->{'Acme::Widget'} }), 3, 'Acme::Widget is provided by three checkouts');
	is(scalar(@{ $shadows->{'Acme::Dup'} }), 2, 'Acme::Dup is duplicated within one checkout');

	foreach my $file (@{ $shadows->{'Acme::Widget'} }) {
		like($file, qr/Acme.Widget\.pm$/, 'names a Widget file');
	}
};

subtest 'unique packages are not returned' => sub {
	my $shadows = find_shadows($checkouts);

	ok(!exists($shadows->{'Acme::OnlyA'}), 'Acme::OnlyA exists in one place only');
	ok(!exists($shadows->{'Acme::Versioned'}), 'versioned package declaration was parsed but is unique');
};

subtest 'a clean tree has no shadows' => sub {
	is_deeply(find_shadows($clean), {}, 'no shadows found');
};

subtest 'ignore excludes provider/package pairs' => sub {
	my $shadows = find_shadows($checkouts, { ignore => [qr/^RepoB/, qr/^RepoA\/Acme::Dup/] });

	is_deeply([sort keys %$shadows], ['Acme::Widget'], 'only Acme::Widget remains shadowed');
	is(scalar(@{ $shadows->{'Acme::Widget'} }), 2, 'the ignored providers were excluded');
};

subtest 'a single checkout can be scanned' => sub {
	my $repoA = File::Spec->catdir($checkouts, 'RepoA');
	my $shadows = find_shadows($repoA);

	is_deeply([sort keys %$shadows], ['Acme::Dup'], 'the vendored t/lib copy is found');
};

subtest 'non-existent directory dies' => sub {
	eval { find_shadows(File::Spec->catdir($FindBin::Bin, 'no', 'such', 'dir')) };
	like($@, qr/not a directory/, 'dies on a non-existent directory');
};

done_testing();
