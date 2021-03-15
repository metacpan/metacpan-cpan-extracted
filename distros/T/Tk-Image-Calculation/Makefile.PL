use 5.006001;
use ExtUtils::MakeMaker;
WriteMakefile(
 	NAME			=> 'Tk::Image::Calculation',
 	VERSION_FROM	=> 'lib/Tk/Image/Calculation.pm',	# finds $VERSION
 	PREREQ_PM		=> {
        # e.g., Module::Name => 1.1
        'ExtUtils::MakeMaker' => '6.98',
    },
    TEST_REQUIRES => {
        # modules only required for testing
        'Test::More' => '0.98',
    },
 	ABSTRACT_FROM	=> 'lib/Tk/Image/Calculation.pm',	# retrieve abstract from module
 	AUTHOR		    => 'Torsten Knorr',
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/asb-capfan/Tk-Image-Calculation',
        },
    },
    LICENSE        => 'perl_5',
    MIN_PERL_VERSION => 5.006001,
);
#-------------------------------------------------


