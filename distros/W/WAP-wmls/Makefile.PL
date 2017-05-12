use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'WAP::wmls',
    'VERSION_FROM'  => 'lib/WAP/wmls.pm',
    'ABSTRACT'      => 'WAP WMLScript compiler',
    'PREREQ_PM'     => {
                        'Parse::Yapp'   => 0,
    },
    'EXE_FILES'     => [ 
                        'bin/wmlsc', 
                        'bin/wmlsd',
    ],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);
