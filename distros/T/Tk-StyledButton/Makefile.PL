require 5.008;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   NAME  => 'Tk::StyledButton',
	'AUTHOR'	=> 'Dean Arnold (darnold[at]presicient.com)',
	'ABSTRACT'	=> 'Styled buttons (plus styled versions of other common widgets)',
	'VERSION_FROM'	=> 'lib/Tk/StyledButton.pm',
	'dist'		=> {
		'COMPRESS'=>'gzip',
		'SUFFIX'	=> '.gz',
		},
   PREREQ_PM => { 'Tk' => '804.027' }
  );
