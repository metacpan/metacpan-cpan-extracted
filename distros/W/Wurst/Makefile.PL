# top level Makefile
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'     => 'Wurst',
    'clean' => {FILES => "*% *.bak *.bck Base/*% out*.au"},
    'linkext' => { LINKTYPE => ''},
    'dist'     => { COMPRESS => 'gzip -f9', SUFFIX => '.gz' },
    'VERSION_FROM'  => "lib/Wurst.pm",
);


