use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Tk::GraphViz',
    'VERSION_FROM'	=> 'GraphViz.pm', # finds $VERSION
    'PREREQ_PM'		=> { Tk => 800.020,
			     Reaper => 1.00 },

    'PM' => { 'GraphViz.pm' => '$(INST_LIBDIR)/GraphViz.pm',
	      'parseRecordLabel.pm' => '$(INST_LIBDIR)/GraphViz/parseRecordLabel.pm'
	    },

    'ABSTRACT' => 'Tk widget (derived from Canvas) for displaying graphs in the GraphViz format.',
    'AUTHOR' => 'Jeremy Slade <jeremy@jkslade.net>',
);
