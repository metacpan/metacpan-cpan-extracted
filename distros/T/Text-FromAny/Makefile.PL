use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::FromAny',
    VERSION_FROM      => 'lib/Text/FromAny.pm', # finds $VERSION
    PREREQ_PM         => {
        'Any::Moose'                  => 0,
        'Try::Tiny'                   => 0,
        'Text::Extract::Word'         => 0,
        'OpenOffice::OODoc'           => '2.101',
        'File::LibMagic'              => 0,
        'Archive::Zip'                => 0,
        'RTF::Parser'                 => '1.09',
        'HTML::FormatText::WithLinks' => 0,
		'CAM::PDF'                    => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/FromAny.pm', # retrieve abstract from module
       AUTHOR         => 'zerodogg <zerodogg@cpan.org>') : ()),
);
