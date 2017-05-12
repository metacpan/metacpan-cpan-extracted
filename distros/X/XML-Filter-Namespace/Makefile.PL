use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'XML::Filter::Namespace',
    VERSION_FROM => 'lib/XML/Filter/Namespace.pm',
    PL_FILES     => { },
    PREREQ_PM    => {
        'Class::Accessor'  => 0.17,
        'Test::More'       => 0,                # For tests.
        'XML::SAX'         => 0,
        'XML::SAX::Writer' => 0.44,             # For tests.
    },
    EXE_FILES     => [qw( filtns )],
    ABSTRACT_FROM => 'lib/XML/Filter/Namespace.pm',
    AUTHOR => 'Dominic Mitchell <cpan@semantico.com>'
);
