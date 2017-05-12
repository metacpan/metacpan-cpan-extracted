use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Schematron',
    'VERSION_FROM' => 'lib/XML/Schematron.pm', # finds $VERSION
    'PREREQ_PM' => {
        XML::SAX                    => 0,
        MooseX::NonMoose            => 0,
        Moose                       => 0,
        MooseX::Types::Path::Class  => 0,
        XML::Filter::BufferText     => 0,
        Check::ISA                  => 0,
        MooseX::Traits              => 0,
     },
);
