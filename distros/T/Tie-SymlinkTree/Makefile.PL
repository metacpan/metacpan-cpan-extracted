use ExtUtils::MakeMaker;
use utf8;
BEGIN { require 5.006; }

WriteMakefile(
    'NAME'          => 'Tie::SymlinkTree',
    'AUTHOR'	    => 'JÃ¶rg Walter <jwalt@cpan.org>',
    'ABSTRACT'	    => 'fast and multi-process-safe persistent storage',
    'VERSION_FROM'  => 'lib/Tie/SymlinkTree.pm', # finds $VERSION
    'PREREQ_PM'     => { },
    'dist' => {
        COMPRESS    =>"gzip -9",
        SUFFIX      =>"gz",
        },
);





