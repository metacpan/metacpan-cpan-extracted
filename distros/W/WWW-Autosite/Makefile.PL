use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'WWW::Autosite',
   VERSION_FROM => 'lib/WWW/Autosite.pm',
   PREREQ_PM => {
 #     'Smart::Comments' => '0',
      'HTML::Template' => '0',
      'File::PathInfo' => '1',
		'File::Path' => 1,
		'File::Copy' => 1,
      'YAML' => '0',
      'Carp' => '0',		
  }, 
  
); 

























