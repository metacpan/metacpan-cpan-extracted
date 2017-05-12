use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tree::Parser',
    'VERSION_FROM'	=> 'lib/Tree/Parser.pm', # finds $VERSION
    'PREREQ_PM'		=> {
            "Test::More"      => 0.47,
            "Test::Exception" => 0.15,
            "Array::Iterator" => 0.04,
            "Tree::Simple"    => 1.03,
            "Scalar::Util"    => 1.10
    }, # e.g., Module::Name => 1.1
);
