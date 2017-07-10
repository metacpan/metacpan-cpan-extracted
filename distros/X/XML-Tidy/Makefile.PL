use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'           => 'XML::Tidy',
# 'VERSION_FROM'   => 'lib/XML/Tidy.pm',
  'VERSION'        => '1.20',
# 'ABSTRACT_FROM'  => 'lib/XML/Tidy.pm',
  'ABSTRACT'       => 'tidy indenting of XML documents',
  'LICENSE'        => 'gpl_3',
  'AUTHOR'         => [ 'Pip Stuart <Pip@CPAN.Org>' ],
  'EXE_FILES'      => [ 'bin/xmltidy' ],
  'TEST_REQUIRES'  => {
    'Test'                           => 0,
    'Test::More'                     => 0,
    'Test::Pod'                      => 0,
    'Test::Pod::Coverage'            => 0,
  }, # Module::Name                  => 1.1,
  'PREREQ_PM'      => {
    'Carp'                           => 0,
    'Math::BaseCnv'                  => 0,
    'XML::XPath'                     => 0,
    'XML::XPath::XMLParser'          => 0,
  },
  'dist'           => { 'COMPRESS'   => 'gzip',
                        'SUFFIX'     => '.tgz' },
);
