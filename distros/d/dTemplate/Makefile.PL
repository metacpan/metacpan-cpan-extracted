use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'dTemplate',
    'VERSION_FROM' => 'dTemplate.pm', # finds $VERSION
#    'OPTIMIZE' => '-Wall -ggdb',
    'dist'      => {
        PREOP => 'perl -MPod::Text -e "pod2text(q(dTemplate.pod))" > README'
    }
);

