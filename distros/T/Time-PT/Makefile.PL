use ExtUtils::MakeMaker;
  # See lib/ExtUtils/MakeMaker.pm for details of how to influence
  # # the contents of the Makefile that is written.
  WriteMakefile(
    'NAME'         => 'Time::PT',
    'VERSION'      => '1.2.565EHOV',
    'ABSTRACT'     => 'objects to store an instant in time',
    'AUTHOR'       => 'Pip Stuart <Pip@CPAN.Org>',
    'EXE_FILES'    => [ 
                        'bin/pt',
                        'bin/fpt',
                        'bin/lspt',
                      ],
    'PREREQ_PM'    => {
      'Time::Zone'                     => 0,
      'Time::DayOfWeek'                => 0,
      'Time::Local'                    => 0,
      'Time::DaysInMonth'              => 0,
      'Time::HiRes'                    => 0,
      'Math::BaseCnv'                  => 0,
    }, # Module::Name => 1.1,
    'dist'         => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'tgz' },
  );