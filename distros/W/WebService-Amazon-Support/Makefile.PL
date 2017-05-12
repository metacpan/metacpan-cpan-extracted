use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::Amazon::Support',
    AUTHOR           => q{Matthew Cox <mcox@cpan.org>},
    VERSION_FROM     => 'lib/WebService/Amazon/Support.pm',
    ABSTRACT_FROM    => 'lib/WebService/Amazon/Support.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
        'AWS::Signature4'       => 0,
        'Carp'                  => 0,
        'Encode'                => 0,
        'HTTP::Request::Common' => 0,
        'JSON'                  => 0,
        'LWP'                   => 0,
        'Params::Validate'      => 0,
        'Readonly'              => 0,
        'WebService::Simple'    => 0,      
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-Amazon-Support-*' },
);
