
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Time::Mock',
  license             => 'perl',
  dist_version_from   => 'lib/Time/Mock.pm',
  requires => {
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  recommends => {
    'Date::Parse' => 2.27,
  },
  add_to_cleanup      => [ qw(Time-Mock-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-Mock',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Time-Mock/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
