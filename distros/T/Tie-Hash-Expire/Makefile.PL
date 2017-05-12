use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Tie::Hash::Expire',
    'VERSION_FROM'	=> 'Expire.pm', # finds $VERSION
    'PREREQ_PM'		=> 	{
					'Test::More'	=> 0,
					'POSIX'		=> 0,
					'Carp'		=> 0,
				},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Expire.pm', # retrieve abstract from module
       AUTHOR     => 'Jeff Yoak <jeff@yoak.com>') : ()),
);
