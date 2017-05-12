
use strict;
use warnings;
use Module::Build;

my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'VCfs',
  license             => 'perl',
  requires => {
    'IPC::Run'                => '0.8',
    'Class::Accessor::Classy' => 'v0.1.3',
  },
  build_requires => {
    'Module::Build' => 0.2808,
    'Test::More'    => 0.72,
  },
  add_to_cleanup      => [ qw(VCfs-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=VCfs',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/VCfs/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
