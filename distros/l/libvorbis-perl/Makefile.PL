use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Ogg::Vorbis',
    'VERSION_FROM' => 'Vorbis.pm',
    'LIBS'	=> ['-logg -lvorbis -lvorbisfile'],
    'DEFINE'	=> '',
    'INC'	=> '-I/usr/local/include/vorbis',
    'EXE_FILES' => ['pogg'],
);
