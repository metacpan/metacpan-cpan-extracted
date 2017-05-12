use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'	=> 'XML-Generator-Pdb',
	'VERSION_FROM' => 'lib/XML/Generator/Pdb.pm',
	'EXE_FILES' => [ 'scripts/pdbtoxml' ],
	'PREREQ_PM' => {
		'Palm::PDB'	=> 0,
		'Palm::Raw'	=> 0
		}
	); 
