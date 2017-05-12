use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'XML::Filter::Cache',
    'VERSION_FROM' => 'lib/XML/Filter/Cache.pm',
    'PREREQ_PM' => {
        XML::SAX => 0.08,
        XML::SAX::Writer => 0.39,
        Digest::MD5 => 2.00,
        Storable => 1.00,
        File::Spec => 0.8,
    },
    'ABSTRACT_FROM' => 'lib/XML/Filter/Cache.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
    clean => {
        FILES => 'cacheroot',
    },
);
