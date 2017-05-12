use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Support IMAP URI",
               NAME          => 'URI::imap',
               PREREQ_PM     => {
                                 'URI' => '',
                                },
               VERSION_FROM  => 'lib/URI/imap.pm',
              );
