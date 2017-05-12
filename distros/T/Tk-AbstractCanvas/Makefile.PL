use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
#   the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Tk::AbstractCanvas',
  'VERSION'      => '1.4.A7QFZHF',
  'ABSTRACT'     => 'Canvas with Abstract center, zoom, && rotate methods',
  'AUTHOR'       => 'Pip Stuart <Pip@CPAN.Org>',
  'EXE_FILES'    => [ 
                    ],
  'PREREQ_PM'    => {
    'Test'                           => 0,
    'Test::Pod'                      => 0,
    'Test::Pod::Coverage'            => 0,
    'Tk'                             => 0,
    'Tk::Canvas'                     => 0,
    'Tk::Derived'                    => 0,
  }, # Module::Name => 1.1,
  'dist'         => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'tgz' },
);