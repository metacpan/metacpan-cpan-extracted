use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'VisualDreams::Yubikey::online',
    'VERSION_FROM'	=> 'online.pm', # finds $VERSION
    'PREREQ_PM'         => { 'Digest::HMAC_SHA1' => '0',
                             'LWP::Simple' => '0',
                             'URI::Escape' => '0',
                             'MIME::Base64' => '0'
                                                         },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'online.pm', # retrieve abstract from module
       AUTHOR     => 'Gunther Voet <oss@xsrv.net>') : ()),
);

META_MERGE      => {
        no_index => {
            package => ['DynaLoader'],
        },
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            homepage    =>      'http://www.xsrv.net/oss',
            bugtracker  =>      'http://rt.cpan.org/Public/Dist/Display.html?Name=VisualDreams-Yubikey_online',
            'Email' =>    'oss@xsrv.net',            
        },
    },
      


