use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> q[Tie::FileHandle::Split],
    'VERSION_FROM'	=> 'lib/Tie/FileHandle/Split.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			'Tie::FileHandle::Base' => 0.1,
			'File::Temp' => 0.16,
			'Carp' => 1.22,
			},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Tie/FileHandle/Split.pm', # retrieve abstract from module
       AUTHOR     => 'Gonzalo Barco <gbarco@cpan.org>') : ()),
);
