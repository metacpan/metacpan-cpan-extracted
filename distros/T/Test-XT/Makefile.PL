use inc::Module::Install 1.01;

all_from      'lib/Test/XT.pm';
test_requires 'Test::More'   => 0.42;
test_requires 'File::Spec'   => 0.80;
test_requires 'File::Remove' => 1.42;

# Stricly speaking we should only force these for RELEASE_TESTING as well.
# But it's handy to run at least one of the test generators all the time
# and these two depednencies aren't that harsh compared to others.
test_requires 'Pod::Simple' => 3.07;
test_requires 'Test::Pod'   => 1.26;

if ( $ENV{RELEASE_TESTING} ) {
	test_requires 'Test::CPAN::Meta'     => 0.12;
	test_requires 'Perl::MinimumVersion' => 1.20;
	test_requires 'Test::MinimumVersion' => 0.008;
	test_requires 'Test::DistManifest'   => 1.003;
	test_requires 'Test::CheckChanges'   => 0.08;
	test_requires 'Test::Pod::Coverage'  => 1.08;
}

WriteAll;
