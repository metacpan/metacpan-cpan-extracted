use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'           => 'Tk::AbstractCanvas',
# 'VERSION_FROM'   => 'lib/Tk/AbstractCanvas.pm',
  'VERSION'        => '1.8',
# 'ABSTRACT_FROM'  => 'lib/Tk/AbstractCanvas.pm',
  'ABSTRACT'       => 'Canvas with Abstract center, zoom, and rotate methods',
  'LICENSE'        => 'gpl_3',
  'AUTHOR'         => [ 'Pip Stuart <Pip@CPAN.Org>' ],
  'TEST_REQUIRES'  => {
    'Test'                           => 0,
    'Test::More'                     => 0,
    'Test::Pod'                      => 0,
    'Test::Pod::Coverage'            => 0,
  }, # Module::Name                  => 1.1,
  'PREREQ_PM'      => {
    'Carp'                           => 0,
  },
  'dist'           => { 'COMPRESS'   => 'gzip',
                        'SUFFIX'     => '.tgz' },
);
