
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'lambda',
  license             => 'perl',
  dist_version_from   => 'lib/lambda.pm',
  requires => {
    perl            => '5.6.2',
  },
  build_requires => {
    'Module::Build' => 0.28,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(lambda-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=lambda',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/lambda/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
