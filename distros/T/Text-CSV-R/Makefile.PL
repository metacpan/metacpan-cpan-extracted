use 5.005003;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Text::CSV::R',
    VERSION_FROM => 'lib/Text/CSV/R.pm',    # finds $VERSION
    PREREQ_PM    => {
        'Text::CSV'    => 1.0,
        'Carp'         => 0,
        'Scalar::Util' => 0,
        'List::Util' => 0,

        # these for testing
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
        'Test::LongString' => 0,
        'File::Temp'       => 0,
    },                                      # e.g., Module::Name => 1.1
    (   ( ExtUtils::MakeMaker->VERSION() gt '6.46' )
        ? ( META_MERGE => {
                resources => {
                    repository => 'http://github.com/lima1/p5-text-csv-r',
                },
            }
            )
        : ()
    ),
    (   ( ExtUtils::MakeMaker->VERSION() gt '6.30' ) ? ( 'LICENSE' => 'perl' )
        : ()
    ),
    (   $] >= 5.005 ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT_FROM =>
                'lib/Text/CSV/R.pm',    # retrieve abstract from module
            AUTHOR => '<limaone@cpan.org>'
            )
        : ()
    ),
);
