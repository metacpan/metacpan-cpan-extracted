use version 0.77;
use Test::Builder::Tester tests => 1;
use Test::More;
use File::Spec::Functions; # Core from 5.005004
use FindBin;
use lib $FindBin::Bin;

my ($error, $remedy, $berror, $bremedy) = do 'prereq_matches_use_info.pl'; # To avoid use and require
require Module::CPANTS::Analyse;
my $target_ver = version->parse($Module::CPANTS::Analyse::VERSION);
my @use = (
	'File::Spec::Functions in PathTools',
	'Term::ANSIColor in Term-ANSIColor',
	'Test::Pod in Test-Pod',
	'Test::Pod::Coverage in Test-Pod-Coverage',
	'Pod::Coverage::TrustPod in Pod-Coverage-TrustPod',
);
push @use, 'Test::Perl::Critic in Test-Perl-Critic' unless $target_ver > version->parse('0.89') || $target_ver == version->parse('0.88');

test_out('not ok 1 - build_prereq_matches_use by Test::Kwalitee::Extra');
test_fail(+6);
test_diag("  Detail: $berror");
test_diag('  Detail: Missing: ' . join(', ', sort @use));
test_diag("  Remedy: $bremedy");

require Test::Kwalitee::Extra;
Test::Kwalitee::Extra->import(qw(:no_plan :minperlver 5.005 !:core !:optional build_prereq_matches_use));

test_test('expected failure of build_prereq_matches_use');
