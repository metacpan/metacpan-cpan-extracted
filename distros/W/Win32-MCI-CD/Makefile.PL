use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Win32::MCI::CD',
    'VERSION_FROM'	=> 'CD.pm',
    'PREREQ_PM'		=> {Win32::API => 0.01 },
    ($] >= 5.005 ?
      (ABSTRACT   => "Play audio cd's on your windows machine via winmm.dll (MCI)",
       AUTHOR     => 'Lennert Ouwerkerk <lennert@kabelfoon.nl>') : ()),
);
