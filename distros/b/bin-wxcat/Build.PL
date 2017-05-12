
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'bin::wxcat',
  license             => 'perl',
  dist_version_from   => 'lib/bin/wxcat.pm',
  requires => {qw(
    Wx                       0.27
    Getopt::Helpful          0.04
    Class::Accessor::Classy  v0.9.0
    wxPerl::Constructors     v0.0.4
    wxPerl::Styles           v0.0.1
  )},
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(bin-wxcat-* META.yml)],
  create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=bin-wxcat',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/bin-wxcat/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
