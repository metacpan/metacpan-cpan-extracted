use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::XPath::Simple',
    'VERSION_FROM' => 'Simple.pm', # finds $VERSION
	'PREREQ_PM'		=> {
    			    Carp => 0.0,
    			    Test::More => 0.18,
			    	XML::Simple => 1.08,
			    }, 
    'AUTHOR'		=> 'Sean Campbell <whytwolf@spots.ab.ca>',
);
