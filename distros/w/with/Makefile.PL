use 5.009004;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $BUILD_REQUIRES = {
 'ExtUtils::MakeMaker' => 0,
 'Test::More'          => 0,
};

sub build_req {
 my $tometa = ' >> $(DISTVNAME)/META.yml;';
 my $build_req = 'echo "build_requires:" ' . $tometa;
 foreach my $mod ( sort { lc $a cmp lc $b } keys %$BUILD_REQUIRES ) {
  my $ver = $BUILD_REQUIRES->{$mod};
  $build_req .= sprintf 'echo "    %-30s %s" %s', "$mod:", $ver, $tometa;
 }
 return $build_req;
}

WriteMakefile(
    NAME          => 'with',
    AUTHOR        => 'Vincent Pit <perl@profvince.com>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/with.pm',
    ABSTRACT_FROM => 'lib/with.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Carp'                 => 0,
        'Filter::Util::Call'   => 0,
        'Scalar::Util'         => 0,
        'Sub::Prototype::Util' => 0.08,
        'Text::Balanced'       => 0,
    },
    dist          => { 
        PREOP                => 'pod2text lib/with.pm > $(DISTVNAME)/README; '
                                . build_req,
        COMPRESS             => 'gzip -9f', SUFFIX => 'gz'
    },
    clean         => { FILES => 'with-* *.gcov *.gcda *.gcno cover_db' },
);
