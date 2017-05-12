use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Generator::Win32OLETypeLib',
    'VERSION_FROM' => 'Win32OLETypeLib.pm', # finds $VERSION
    'PREREQ_PM' => { Win32::OLE => 0, 
            Win32::OLE::Const => 0,
            Win32::OLE::TypeInfo => 0,
            },
);
