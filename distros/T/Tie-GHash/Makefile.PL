use Inline::MakeMaker;
#use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteInlineMakefile(
    'NAME'		=> 'Tie::GHash',
    'VERSION_FROM'	=> 'GHash.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
