use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MP3::Tag',
    'VERSION_FROM'	=> 'Tag.pm', # finds $VERSION
    'PMLIBDIRS'         => ['TAG', 'MP3::TAG'],
    'AUTHOR'            => '"Thomas Geffert" <thg@users.sourceforge.net>',
    'PREREQ_PM'         => {Compress::Zlib=>0},
);
