use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Text::StripAccents',
    'VERSION_FROM'      => 'lib/Text/StripAccents.pm', # finds $VERSION
    'PREREQ_PM'         => {}, 
	'MAN3PODS'	=> { },
);
