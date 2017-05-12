use ExtUtils::MakeMaker;
WriteMakefile(
	      'NAME'		=> 'ToolSet::Bundle',
	      'VERSION_FROM'	=> 'lib/Bundle/ToolSet.pm',
	      'PREREQ_PM'       => {ToolSet => 0.99, 'Pod::Simple'=>undef},
);
