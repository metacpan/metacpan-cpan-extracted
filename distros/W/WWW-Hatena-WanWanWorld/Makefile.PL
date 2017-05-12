use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WWW::Hatena::WanWanWorld',
    VERSION_FROM      => 'lib/WWW/Hatena/WanWanWorld.pm', # finds $VERSION
    PREREQ_PM         => {
                             LWP::UserAgent => 0,
                             HTTP::Cookies => 0,
                             Carp => 0,
                             Digest::MD5 => 0,
                             JSON => 0,
                             Location::GeoTool => 0,
                             Jcode =>0,
                         },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WWW/Hatena/WanWanWorld.pm',
       AUTHOR         => 'OHTSUKA Ko-hei <nene@kokogiko.net>') : ()),
);
