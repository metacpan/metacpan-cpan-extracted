use ExtUtils::MakeMaker;

WriteMakefile(
        NAME         => 'Time::SoFar',
        VERSION_FROM => 'SoFar.pm',
        'linkext'    => {LINKTYPE => ''},
        'dist'       =>    {COMPRESS=>'gzip', SUFFIX=>'gz'},
        ($] >= 5.005?
	   (ABSTRACT => 'Elapsed script run time',
            AUTHOR   => 'Eli the Bearded <eli+cpan@panix.com>')
         : ()
        ),
);
