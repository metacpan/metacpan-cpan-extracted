use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'	=> 'XML-Handler-Pdb',
	'VERSION_FROM' => 'lib/XML/Handler/Pdb.pm',
	'EXE_FILES' => [ 'scripts/xmltopdb' ],
	'PREREQ_PM' => {
		'Palm::PDB'	=> 0,
		'Palm::Raw'	=> 0,
		'XML::Handler::Subs' => 0	
		}
	); 
