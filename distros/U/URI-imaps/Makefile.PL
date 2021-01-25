use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Support IMAPS URI",
               NAME          => 'URI::imaps',
               PREREQ_PM     => {
                                 'URI' => 0,
                                },
               VERSION_FROM  => 'lib/URI/imaps.pm',
               ($ExtUtils::MakeMaker::VERSION < 6.31 ? () : ('LICENSE'=> 'perl_5')),
               ($ExtUtils::MakeMaker::VERSION < 6.46 ? () :
                 ( META_MERGE => {
                       'meta-spec' => { version => 2 },
                       resources => {
                           repository => {
                               url  => 'https://github.com/alexm/URI-imaps.git',
                               web  => 'https://github.com/alexm/URI-imaps',
                               type => 'git',
                           },
                           bugtracker => {
                               "web" => "https://github.com/alexm/URI-imaps/issues",
                           },
                       },
                   },
                 ),
               ),
              );
