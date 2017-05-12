use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::RAI::TrackBack',
    'VERSION_FROM'	=> 'lib/XML/RAI/TrackBack.pm',
    'PREREQ_PM'		=> { XML::RAI=>1.3, File::Spec=>0, Test::More=>0}, 
);
