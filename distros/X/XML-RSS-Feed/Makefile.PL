use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::RSS::Feed',
    AUTHOR        => 'Jeff Bisbee <jbisbee@cpan.org>',
    VERSION_FROM  => 'lib/XML/RSS/Feed.pm',
    ABSTRACT_FROM => 'lib/XML/RSS/Feed.pm',
    PL_FILES      => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'XML::RSS'       => 0,
        'Clone'          => 0,
        'Storable'       => 0,
        'Time::HiRes'    => 0,
        'URI'            => 0,
        'Digest::MD5'    => 0,
        'Encode'         => 0,
        'HTML::Entities' => 0,
        'Carp'           => 0,
        'URI::Escape'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'XML-RSS-Feed-*' },
    LICENSE => 'perl',
);
