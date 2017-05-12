
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Tree::Base',
  license             => 'perl',
  dist_version_from   => 'lib/Tree/Base.pm',
  requires => {
    'Scalar::Util' => 0,
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Tree-Base-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Base',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Tree-Base/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
