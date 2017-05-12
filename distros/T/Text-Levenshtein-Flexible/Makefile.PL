use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Text::Levenshtein::Flexible',
    VERSION_FROM      => 'lib/Text/Levenshtein/Flexible.pm',
    MIN_PERL_VERSION  => 5.008008,
    TEST_REQUIRES     => {
        'Test::LeakTrace'   => 0,
        'Test::Exception'   => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Levenshtein/Flexible.pm', # retrieve abstract from module
       AUTHOR         => 'Matthias Bethke <matthias@towiski.de>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '-ggdb', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    dist => {
        COMPRESS        => 'bzip2',
        SUFFIX          => '.bz2',
    },
    LICENSE           => 'perl',
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
