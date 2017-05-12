use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Toadfarm::Plugin::Letsencrypt',
  VERSION_FROM => 'lib/Toadfarm/Plugin/Letsencrypt.pm',
  AUTHOR       => 'Stefan Adams <sadams@cpan.org>',
  PREREQ_PM    => {'Toadfarm' => '0.69'},
  test         => {TESTS => 't/*.t'}
);
