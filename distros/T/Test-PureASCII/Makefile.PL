
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Test::PureASCII',
               VERSION_FROM => 'lib/Test/PureASCII.pm',
               PREREQ_PM => { 'Test::Builder' => 0 },
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>');
