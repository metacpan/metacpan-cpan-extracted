use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	    => 'Tie::Table',
    'VERSION_FROM'  => 'Table.pm', # finds $VERSION
    'dist'	    => {
	PREOP => $^X.' -MPod::Text -e "pod2text(q(Table.pm))" > README'
    }
);
