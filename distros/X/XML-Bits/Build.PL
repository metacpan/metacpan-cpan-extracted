
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'XML::Bits',
  license             => 'perl',
  dist_version_from   => 'lib/XML/Bits.pm',
  requires => {
    'Tree::Base'              => 'v0.10.2',
    'Class::Accessor::Classy' => 'v0.9.0',
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(XML-Bits-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Bits',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/XML-Bits/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
