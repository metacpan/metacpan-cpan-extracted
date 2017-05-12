use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tie::Scalar::MarginOfError',
    VERSION_FROM      => 'lib/Tie/Scalar/MarginOfError.pm',
    PREREQ_PM         => 
	{ 
		'Tie::Scalar' => '1.00',
		'Test::More'  => '0.47',
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Stray Toaster <coder@stray-toaster.co.uk>') : ()),
);
