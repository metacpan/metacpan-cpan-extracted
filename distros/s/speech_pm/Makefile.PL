use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Speech::Synthesiser',
    'AUTHOR'    => 'Richard Caley <R.Caley@ed.ac.uk>',
    'ABSTRACT'  => 'Speech synthesis from Perl',
    'PMLIBDIRS' => [ 'Speech', 'Audio' ],
    'VERSION_FROM' => 'Speech/Synthesiser.pm', # finds $VERSION
);
