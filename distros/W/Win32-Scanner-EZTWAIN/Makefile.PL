use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Win32::Scanner::EZTWAIN',
    'VERSION_FROM'	=> 'EZTWAIN.pm',
    'PREREQ_PM'		=> { Win32::API => 0.01 },
    ($] >= 5.005 ?
      (ABSTRACT   => 'An interface to the classic EZTWAIN library',
       AUTHOR     => 'Lennert Ouwerkerk <lennert@kabelfoon.nl>') : ()),
);
