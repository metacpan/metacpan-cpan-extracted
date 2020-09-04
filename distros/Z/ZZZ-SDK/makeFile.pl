use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.66,
    },
    PMLIBDIRS       => [qw(src inc)],
    PREREQ_PM          => {
        'File::Path'                => 0,
        'strict'                    => 0,
        'warnings'                  => 0,
        'File::Spec::Functions'     => 0,
        'HTTP::Request'             => 0,
        'HTTP::Headers'             => 0,
        'Switch'                    => 2.17,
        'Scalar::Util'              => 0,
        'Try::Catch'                => 1.1.0,
        'URI::Split'                => 0,
        'MIME::Base64'              => 3.13,
        'DateTime::Format::ISO8601' => 0.08,
        'JSON::Parse'               => 0.56,
        'List::MoreUtils'           => 0.33,
        'Time::HiRes'               => 0,
        'Moose'                     => 2.1202
    },
    BUILD_REQUIRES     => {
        'LWP::UserAgent' => 0,
        'DBI'            => 1.6,
        'Log::Handler'   => 0.88,
        'HTTP::Request'  => 0,
    },
    NAME               => 'ZZZ::SDK',
    VERSION            => '0.0.2',
    AUTHOR             => q{Standard User <stdcrm@cpan.org>},
    # META_ADD           =>{
    #     provides => {
    #         'ZZZ::SDK' => {
    #             file => 'Provides.pm.PL',
    #             version => '0.0.1'
    #         }
    #     }
    # }
);
