use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Test::Pockito',
    VERSION_FROM => 'lib/Test/Pockito.pm',                  # finds \$VERSION
    AUTHOR       => 'Spencer Portee (exussum@gmail.com)',
    PREREQ_PM    => {
        'IO::String'   => 1.08,
        'Class::MOP'   => 1.02,
        'Test::Simple' => 0.44,
	'Scalar::Util::Reftype' => => 0.40,
    },
    test => { TESTS => 't/*.t t/exported/*.t' }
);
