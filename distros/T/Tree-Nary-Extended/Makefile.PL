use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tree::Nary::Extended',
    'VERSION_FROM'	=> 'Extended.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	{
		Tree::Nary => 1.21,
		
		SQL::Generator => 0,
		
		DBI => 0,
		
		IO::Extended => 0.05,
		
	}, # e.g., Module::Name => 1.1
);
