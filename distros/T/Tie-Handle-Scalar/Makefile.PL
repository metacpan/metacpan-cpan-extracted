use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Tie::Handle::Scalar',
    'VERSION_FROM' => 'Scalar.pm', # finds $VERSION
);
