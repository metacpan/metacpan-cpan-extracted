use 5.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::Names',
    VERSION_FROM      => 'lib/Text/Names.pm', # finds $VERSION
    PREREQ_PM         => {
        'Text::Capitalize' => 1.1,
        'Text::LevenshteinXS' => 0.03,
        'Test::More' => 0.96
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Names.pm', # retrieve abstract from module
       AUTHOR         => 'David Bourget') : ()),
    ($ExtUtils::MakeMaker::VERSION < 6.46
      ? ()
      : ( META_MERGE  => {
              resources => {
                  repository => 'https://github.com/dbourget/Text-Names',
              },
          },
        )
    ), 
);
