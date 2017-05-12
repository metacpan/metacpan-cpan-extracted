
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Tie::Array::Packed',
               VERSION_FROM => 'lib/Tie/Array/Packed.pm',
               PREREQ_PM => { Test::More => 0 },
               ABSTRACT_FROM => 'lib/Tie/Array/Packed.pm',
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS => [''],
               DEFINE => '',
               INC => '-I.',
               OBJECT => '$(O_FILES)',
             );
