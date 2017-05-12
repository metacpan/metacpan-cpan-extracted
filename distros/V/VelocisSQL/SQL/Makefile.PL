use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Velocis::SQL',
    'VERSION_FROM' => 'SQL.pm', # finds $VERSION
    'LIBS'	=> ['-L/usr/local/velocis/lib -lrdscli -lm'],
    'DEFINE'	=> '-DUNIX -DBSDOS',
    'INC'	=> '-I/usr/local/velocis/include',
);
