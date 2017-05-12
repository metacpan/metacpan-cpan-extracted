use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	AUTHOR => 'Paul Bournival (paulbb@cajun.nu)',
	NAME	=> 'Audio::Xmpcr',
	VERSION => 1.02,
	EXE_FILES => ['bin/xmpcrd','bin/xmripper','bin/xmfinder'],
	LIBS	=> [''],   
	DEFINE	=> '',   
	INC	=> '',     
	PREREQ_PM => {
		'Device::SerialPort'    => '0', 
	}
);
