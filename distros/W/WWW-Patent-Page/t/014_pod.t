
use Test::More;

if ( (not exists($ENV{TEST_AUTHOR})) or not ($ENV{TEST_AUTHOR} eq 'Wanda_B_Anon' )) {
	my $msg = 'Author test only.  Set $ENV{TEST_AUTHOR} to "Wanda_B_Anon" to run.';
	plan( skip_all => $msg );
}

eval "use Test::Pod 1.00";

plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
