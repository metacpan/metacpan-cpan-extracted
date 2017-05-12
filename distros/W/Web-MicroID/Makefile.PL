use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Web::MicroID',
    VERSION_FROM => 'lib/Web/MicroID.pm', # finds $VERSION
    PREREQ_PM    => {
        Digest::SHA1 => 2,
        Digest::MD5  => 2
    }, (
        ## Add these new keywords supported since 5.005
        ## retrieve abstract from module
        $] >= 5.005 ? (
            ABSTRACT_FROM  => 'lib/Web/MicroID.pm',
            AUTHOR         => 'Jim Walker <jim@reclaw.com>'
        ) : ()),
);

