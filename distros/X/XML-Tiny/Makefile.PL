use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'XML::Tiny',
    VERSION_FROM => 'lib/XML/Tiny.pm', # finds $VERSION
    PREREQ_PM    => {
        # no pre-reqs!
    }
);
