
use ExtUtils::MakeMaker;

WriteMakefile( NAME           => 'Tie::Array::Packed::Auto',
               VERSION_FROM   => 'lib/Tie/Array/Packed/Auto.pm',
               PREREQ_PM      => { Tie::Array::PackedC => 0 },
               ABSTRACT_FROM  => 'lib/Tie/Array/Packed/Auto.pm',
               AUTHOR         => 'Salvador Fandino <sfandino@yahoo.com>'
             );

