use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'YAPE::Regex::Explain',
    'VERSION_FROM'  => 'Explain.pm',
    'LICENSE'       => 'perl',
    'PREREQ_PM' => {
        'YAPE::Regex' => 0,
        'Test::More'  => 0,
    }
);
