use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Atom::App',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/XML/Atom/App.pm',
    ABSTRACT_FROM       => 'lib/XML/Atom/App.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'XML::Atom'  => 0,
        'XML::Atom::Feed'  => 0,        
        'XML::Atom::Entry' => 0, 
        'XML::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Atom-App-*' },
);
