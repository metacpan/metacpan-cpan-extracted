use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'           => 'Time::DayOfWeek',
# 'VERSION_FROM'   => 'lib/Time/DayOfWeek.pm',
  'VERSION'        => '1.8',
# 'ABSTRACT_FROM'  => 'lib/Time/DayOfWeek.pm',
  'ABSTRACT'       => 'calculate which Day-of-Week a date is',
  'LICENSE'        => 'gpl_3',
  'AUTHOR'         => [ 'Pip Stuart <Pip@CPAN.Org>' ],
  'EXE_FILES'      => [ 'bin/dow' ],
  'TEST_REQUIRES'  => {
    'Test'                           => 0,
    'Test::More'                     => 0,
    'Test::Pod'                      => 0,
    'Test::Pod::Coverage'            => 0,
  }, # Module::Name                  => 1.1,
  'PREREQ_PM'      => {
  },
  'dist'           => { 'COMPRESS'   => 'gzip',
                        'SUFFIX'     => '.tgz' },
);
