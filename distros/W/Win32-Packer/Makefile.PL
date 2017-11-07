use 5.024001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile( NAME              => 'Win32::Packer',
               VERSION_FROM      => 'lib/Win32/Packer.pm',
               PREREQ_PM         => { 'Log::Any' => 0,
                                      'Win32::Ldd' => 0,
                                      'Module::ScanDeps' => 0,
                                      'Moo' => 0,
                                      'XML::FromPerl' => 0,
                                      'Path::Tiny' => 0,
                                      'Win32' => 0,
                                      'namespace::autoclean' => 0,
                                      'Archive::Zip' => 0,
                                    },
               ABSTRACT_FROM     => 'lib/Win32/Packer.pm',
               AUTHOR            => 'Salvador Fandiño <sfandino@yahoo.com>',
               LICENSE           => 'gpl3',
             );
