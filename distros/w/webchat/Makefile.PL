use ExtUtils::MakeMaker;

WriteMakefile(
   NAME      => "webchat",
   'VERSION_FROM'      => 'lib/WWW/Chat.pm', # finds $VERSION
   PREREQ_PM => {
                  'HTML::Parser' => '2.21',
		  'Data::Dump'   => '0.01',
                  'URI'          => '1.00',
		  'LWP'          => '5.47',
                },
   EXE_FILES => [ 'webchatpp' ],
   dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
);
