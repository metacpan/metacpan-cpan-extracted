use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'XML::DoubleEncodedEntities',
    META_MERGE => {
        license => 'other',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-XML-DoubleEncodedEntities',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-XML-DoubleEncodedEntities/issues'
        }
    },
    VERSION_FROM => 'lib/XML/DoubleEncodedEntities.pm', # finds $VERSION
    PREREQ_PM    => {
        Test::Simple => 0.64
    }
);
