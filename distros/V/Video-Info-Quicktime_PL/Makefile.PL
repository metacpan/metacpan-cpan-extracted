use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'     	=> 'Video::Info::Quicktime_PL',
              'VERSION_FROM'	=> 'Quicktime_PL.pm', # finds $VERSION
              'PREREQ_PM'	=> { Video::Info => 0.991,
                Class::MakeMethods::Emulator => 1.0,
                Compress::Zlib => 0,
                Digest::MD5 => 0,
                },
              
              ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               (ABSTRACT_FROM => 'Quicktime_PL.pm', 
                AUTHOR     => 'W S Hoge <shoge at perl dot org>') : ()),
);
