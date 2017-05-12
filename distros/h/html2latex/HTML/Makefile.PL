use ExtUtils::MakeMaker;
			       
WriteMakefile(	      
	      'NAME'		=> 'HTML::Latex',
	      'VERSION_FROM'	=> 'Latex.pm',
	      'PREREQ_PM'	=> { 
				    XML::Simple       => 1.04,
				    HTML::TreeBuilder => 2.97,
				   },
	     );
