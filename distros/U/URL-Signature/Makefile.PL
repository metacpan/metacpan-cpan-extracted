use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'URL::Signature',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/URL/Signature.pm',
    ABSTRACT_FROM       => 'lib/URL/Signature.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'URI'             => '1.60',
        'URI::QueryParam' => 0,
        'MIME::Base64'    => '3.11',
        'Digest::HMAC'    => 0,
        'Carp'            => 0,
        'Class::Load'     => 0,
        'Params::Util'    => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'URL-Signature-*' },
);
