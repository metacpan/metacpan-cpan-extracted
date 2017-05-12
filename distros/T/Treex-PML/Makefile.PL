require 5.008000;
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'Treex::PML',
  'VERSION_FROM' => 'lib/Treex/PML.pm',
  'PREREQ_PM' => {
                   'File::ShareDir' => '1.00',
                   'File::Which' => 0,
                   'IO::Zlib' => 0,
                   'LWP::UserAgent' => 0,
                   'Test::More' => 0,
                   'UNIVERSAL::DOES' => '0.004',
                   'URI' => '1.35',
                   eval { require XML::CompactTree::XS;
                          '0.03' gt $XML::CompactTree::XS::VERSION
                        } ? ('XML::CompactTree::XS' => '0.03')
                          : (),
                   'XML::CompactTree' => '0.03',
                   'XML::LibXML' => '1.69',
                   'XML::Writer' => '0.606'
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [],
  'PL_FILES' => {}
)
;
