use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'XML::FromPerl',
               VERSION_FROM  => 'lib/XML/FromPerl.pm',
               PREREQ_PM     => { 'XML::LibXML' => 0 },
               ABSTRACT_FROM => 'lib/XML/FromPerl.pm',
               AUTHOR        => 'Salvador Fandiño <sfandino@yahoo.com>',
               LICENSE       => 'perl',
               META_MERGE    => { resources =>
                                  { repository => 'https://github.com/salva/p5-XML-FromPerl' }},
             );
