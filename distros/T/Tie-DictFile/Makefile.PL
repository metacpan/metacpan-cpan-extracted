use ExtUtils::MakeMaker;


use strict;

             

WriteMakefile(
	NAME			=> 'Tie::DictFile',
	VERSION_FROM   	=> 'lib/Tie/DictFile.pm',
	'dist'	  		=>	{COMPRESS=>'gzip', SUFFIX=>'gz'},
	'PREREQ_PM'	  	=>	{'Class::ISA' => 0 , 'Test::More' => 0},
	($] >= 5.005
	    ? (ABSTRACT	=> 'Ties hashes to dictionary files',
	       AUTHOR  	=> 'Alex Nunes <alex@noptr.net>')
	    : ()
	),
) ;




