use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $pm='CheckbuttonGroup';

WriteMakefile(
    'NAME'		=> "Tk::$pm",
    'DISTNAME'	=> "Tk-$pm",
    'VERSION_FROM'	=> "$pm.pm",
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    'PREREQ_PM'		=> {
    	"Tk"		=> "402.000",
    	"Tie::IxHash" => 0,
    },
    ($] >= 5.005 ?
    	(ABSTRACT => 'Radiobutton Group',
    	AUTHOR => 'Joseph Annino (jannino@jannino.com)') : (),
  	), 	
);
