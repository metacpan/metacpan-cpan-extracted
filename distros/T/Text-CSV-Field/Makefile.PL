use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Field',
    VERSION_FROM      => 'lib/Text/CSV/Field.pm', # finds $VERSION
);
