use strict;
use warnings;

use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'          => 'Test::MockDBI',
  'VERSION_FROM'  => 'lib/Test/MockDBI.pm',
  'ABSTRACT_FROM' => 'lib/Test/MockDBI.pm',
  'AUTHOR'        => 'Mark Leighton Fisher <mark-fisher@fisherscreek.com>',
  'LICENSE'       => 'perl',
  'META_MERGE'    => {
    resources => { repository => 'https://github.com/aff/Test-MockDBI', },
    keywords => [qw [Test Mock DBI database]],
  },
  'BUILD_REQUIRES' => { 'CPAN::Meta' => 0, },
  'PREREQ_PM'      => {
    'DBI'                   => 0,
    'Test::MockObject'      => 0.14,
    'Test::More'            => 0,
    'File::Spec::Functions' => 0,
    'Test::Warn'            => 0,
    'Test::Differences'     => 0,
    'Scalar::Util'          => 0,
    'Carp'                  => 0,
    'Clone'                 => 0
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Test-MockDBI-*' },
);

__END__
