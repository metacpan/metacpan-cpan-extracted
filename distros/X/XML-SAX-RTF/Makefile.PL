use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'XML::SAX::RTF',
    'VERSION_FROM' => 'RTF.pm',                 # finds $VERSION
    'PREREQ_PM'         => { 'XML::SAX' => 0 }  # require XML::SAX
 );

