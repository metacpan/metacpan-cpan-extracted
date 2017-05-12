use ExtUtils::MakeMaker;

print "The tests expect that the environment variables A9USER and A9PASSWD are set, if not, no tests that require connection to the service will be run\n";

WriteMakefile(
     NAME          => 'WWW::A9Toolbar',
     VERSION_FROM  => 'lib/WWW/A9Toolbar.pm',
     PREREQ_PM     => { 'WWW::Mechanize'             => 0,
                        'WWW::Mechanize::FormFiller' => 0,
                        'URI'                        => 0,
                        'URI::URL'                   => 0,
                        'URI::QueryParam'            => 0,
                        'Net::DNS'                   => 0,
                        'XML::Simple'                => 0,
                        'List::MoreUtils'            => 0,
                    },
);
