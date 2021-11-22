use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Text::Document',
    'VERSION'		=> '1.08',
    'PREREQ_PM'		=> {
    	Bit::Vector => 7.4,
	    FileHandle => 2.00,
	    DB_File => 1.843
    }, 
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
