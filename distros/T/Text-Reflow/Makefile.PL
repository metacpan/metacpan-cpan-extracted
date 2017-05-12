use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'ABSTRACT'          => "Reflow text files using Knuth's paragraphing algorithm",
    'AUTHOR'            => ['Michael Larsen, larsen@edu.upenn.math',
                            'Martin Ward, martin@gkc.org.uk'],
    'NAME'		=> 'Text::Reflow',
    'VERSION_FROM'	=> 'Reflow.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
    'LICENSE'           => 'Perl',
    'EXE_FILES'         => [ 'reflow' ],
);
