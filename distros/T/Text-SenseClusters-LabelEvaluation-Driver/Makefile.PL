use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;



# Reference: http://search.cpan.org/~mschwern/ExtUtils-MakeMaker-6.62/lib/ExtUtils/MakeMaker.pm
# Things added here:
#    NAME              = Name of the main module, which act as point of start.
#    AUTHOR            = Name of the author.
#    VERSION_FROM      = Place from where to find the version of the module.
#    ABSTRACT_FROM     = Place from where to find the abstract information about the module.
#    PREREQ_PM         = {}, # e.g., Module::Name => 1.1
#    EXE_FILES         = [map "bin/$_", @programs],


WriteMakefile(
    NAME                => 'Text::SenseClusters::LabelEvaluation::Driver',
    AUTHOR              => q{Ted Pedersen <tpederse at d.umn.edu>},
    VERSION_FROM        => 'lib/Text/SenseClusters/LabelEvaluation/Driver.pm',
    ABSTRACT_FROM       => 'lib/Text/SenseClusters/LabelEvaluation/Driver.pm',
    ($ExtUtils::MakeMaker::VERSION ge '6.30_00'
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
    'Test::More' 			=> 0,
	'Text::Similarity' 		=> 0.09,
	'WWW::Wikipedia' 		=> 2.00,
	'Algorithm::Munkres'	=> 0.08
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-SenseClusters-LabelEvaluation-*' },
);
