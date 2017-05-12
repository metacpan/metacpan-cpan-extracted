use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Win32::MSI::DB',
    'VERSION_FROM' => 'DB.pm',
    'PREREQ_PM'	   => {
        'Win32::API' => 0,
      },
    'NORECURS'     => 1,
  ($] ge '5.005') ? (
    'AUTHOR'       => 'PMarek (pmarek@cpan.org)',
    'ABSTRACT'     => 'Interface for MSI files',
  ) : (),
);
