use strict;
use warnings;
use Module::Build;

# Subclass to add a `./Build critic` action that runs Perl::Critic
# against lib/ and t/ at the project's --gentle severity. Same check
# as the author-mode test in t/author-perlcritic.t -- this just lets
# you invoke it standalone without running the full test suite.
my $class = Module::Build->subclass(
	class => 'Test::MockModule::Builder',
	code => <<'CRITIC_ACTION',
sub ACTION_critic {
	my $self = shift;
	eval { require Test::Perl::Critic; 1 }
		or die "./Build critic requires Test::Perl::Critic. "
		     . "Install it with: cpanm Test::Perl::Critic\n";
	Test::Perl::Critic->import(-severity => 'gentle');
	Test::Perl::Critic::all_critic_ok('lib', 't');
}
CRITIC_ACTION
);

my $builder = $class->new(
	module_name         => 'Test::MockModule',
	create_license      => 1,
	license             => 'perl',
	dist_author         => [q{Current Maintainer: Geoff Franks <gfranks@cpan.org>}, q{Original Author: Simon Flack <simonflk _AT_ cpan.org>}],
	meta_merge => {
		resources => {
			homepage   => 'https://github.com/geofffranks/test-mockmodule',
			bugtracker => 'https://github.com/geofffranks/test-mockmodule/issues',
			repository => 'git://github.com/geofffranks/test-mockmodule.git',
		},
	},

	configure_requires => {
		'Module::Build' => '0.4234',
	},
	requires => {
	    'perl'                => 5.006,
		'Carp'                => 0,
		'Scalar::Util'        => 0,
		'SUPER'               => '1.20',
	},
	test_requires => {
		'Test::More'          => 0.88,
		'Test::Warnings'      => 0,
	},
	# Moose, Mouse, Class::Load and Test::Exception are exercised ONLY by the
	# t/moose_*.t and t/mouse_*.t MOP-integration tests added for GH #55. Each
	# of those files opens with `eval { require Moose } or plan skip_all`, so
	# the suite passes cleanly without them. They are therefore OPTIONAL, not
	# required: declaring them as `recommends` keeps a plain
	# `cpanm Test::MockModule` from dragging in two full Perl OO systems (GH #90).
	#
	# NOTE: Module::Build 0.42xx cannot emit *test-phase* recommends -- a
	# `prereqs` key in meta_merge/meta_add is silently dropped -- so the
	# top-level `recommends` property is used, which lands these under
	# runtime/recommends in META. That is cosmetic: no CPAN client installs
	# recommends of any phase by default, and `cpanm --with-recommends` (used
	# by .github/workflows/testsuite.yml) installs them regardless of phase.
	# Do NOT move these back into test_requires.
	recommends => {
		'Test::Exception'     => 0,
		'Class::Load'         => 0,
		'Moose'               => 0,
		'Mouse'               => 0,
	},

	add_to_cleanup => [
		'Test-MockModule-*',
		'cover_db',
		'*.rpm',
		'*.deb',
	]
);

$builder->create_build_script();
