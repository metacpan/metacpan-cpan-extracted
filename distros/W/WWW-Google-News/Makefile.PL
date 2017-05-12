use ExtUtils::MakeMaker;
my $module = 'News.pm';
WriteMakefile(
              NAME         => 'WWW::Google::News',
              VERSION_FROM => $module,
              PREREQ_PM    => {
                               Test::More => 0,
                              },
              AUTHOR       => 'Greg McCarroll <greg@mccarroll.demon.co.uk>',
             );


