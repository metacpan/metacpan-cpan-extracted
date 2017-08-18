use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'XML::Tiny',
    META_MERGE => {
        license => 'other',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-XML-Tiny',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-XML-Tiny/issues'
        }
    },
    VERSION_FROM => 'lib/XML/Tiny.pm', # finds $VERSION
    PREREQ_PM    => {
        # no pre-reqs!
    }
);
