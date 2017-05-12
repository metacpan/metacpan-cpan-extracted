use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WWW::FastPass',
    VERSION_FROM      => 'lib/WWW/FastPass.pm',
    LICENSE           => 'perl',
    META_MERGE        => {
        resources => {
            repository => 'https://github.com/tomhrr/p5-WWW-FastPass'
        }
    },
    PREREQ_PM         => { 'Net::OAuth'   => 0,
                           'Digest::SHA1' => 0,
                           'URI'          => 0, },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WWW/FastPass.pm',
       AUTHOR         => 'Tom Harrison <tomhrr@cpan.org>') : ()),
);

1;
