
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Text::Slidez',
  license             => 'perl',
  dist_version_from   => 'lib/Text/Slidez.pm',
  requires => {
    'Shebangml'               => 0,
    'Getopt::AsDocumented'    => 0,
    'XML::Bits'               => 0,
    'File::Fu'                => 'v0.0.6',
    'Text::VimColor'          => 0.11,
    'Class::Accessor::Classy' => 'v0.9.1',
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Text-Slidez-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Slidez',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Text-Slidez/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
