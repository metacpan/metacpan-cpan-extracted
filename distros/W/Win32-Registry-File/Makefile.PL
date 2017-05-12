use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Win32::Registry::File',
    'VERSION_FROM' => 'File.pm', # finds $VERSION
    ($] < 5.005 ? () : (
	AUTHOR  => 'Albert K. T. Hui <avatar@deva.net>',
	ABSTRACT_FROM => 'File.pm',
    )),
    'PREREQ_PM' => {
	'Tie::IxHash'   => 1.21,
    },
);
