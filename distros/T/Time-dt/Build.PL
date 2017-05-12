
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Time::dt',
  license             => 'perl',
  requires => {
    'Time::Piece' => '1.20', # dst strptime
  },
  build_requires => {
    'Module::Build' => 0.34,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Time-dt-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage => 'http://enobacon.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-dt',
      #MailingList => 'mailto:...',
      repository => 'git://git.enobacon.com/Time-dt.pm.git',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
