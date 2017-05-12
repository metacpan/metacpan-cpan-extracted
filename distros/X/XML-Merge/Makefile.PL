use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'           => 'XML::Merge',
# 'VERSION_FROM'   => 'lib/XML/Merge.pm',
  'VERSION'        => '1.4',
# 'ABSTRACT_FROM'  => 'lib/XML/Merge.pm',
  'ABSTRACT'       => 'flexibly merge XML documents',
  'LICENSE'        => 'gpl_3',
  'AUTHOR'         => [ 'Pip Stuart <Pip@CPAN.Org>' ],
  'EXE_FILES'      => [ ],
  'TEST_REQUIRES'  => {
    'Test'                           => 0,
    'Test::More'                     => 0,
    'Test::Pod'                      => 0,
    'Test::Pod::Coverage'            => 0,
  }, # Module::Name                  => 1.1,
  'PREREQ_PM'      => {
    'Carp'                           => 0,
    'XML::Tidy'                      => 0,
  },
  'dist'           => { 'COMPRESS'   => 'gzip',
                        'SUFFIX'     => '.tgz' },
);
