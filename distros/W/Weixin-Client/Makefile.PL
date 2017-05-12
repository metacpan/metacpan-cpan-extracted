use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Weixin::Client',
    VERSION_FROM      => 'lib/Weixin/Client.pm', # finds $VERSION
    DISTNAME            => 'Weixin-Client',
    LICENSE             => "perl",
    PREREQ_PM         => {
        "JSON"                  => 0,
        "Time::Piece"           => 0,
        "Time::Seconds"         => 0, 
        "Encode::Locale"        => 0,
        "AnyEvent::HTTP"        => 0,
        "LWP::UserAgent"        => 0,
        "LWP::Protocol::https"  => 0,
    }, # e.g., Module::Name => 1.1
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Weixin-Client-* MANIFEST' },
    META_MERGE => {
        resources => {     
            repository=>{
                type    => 'git',
                url     => 'git://github.com/sjdy521/pfwx.git',
                web     =>  'https://github.com/sjdy521/pfwx',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       #ABSTRACT_FROM  => 'lib/Webqq/Client.pm', # retrieve abstract from module
       ABSTRACT       => 'Weixin::Client - A Weixin Client in Perl Language',
       AUTHOR         => 'sjdy521 <sjdy521@163.com>') : ()),
);
