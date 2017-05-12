use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    # META.yml source data
    NAME                => 'WWW::Myspace',
    VERSION_FROM        => 'lib/WWW/Myspace.pm',
    ABSTRACT_FROM       => 'lib/WWW/Myspace.pm',
    AUTHOR              => 'Grant Grueninger <grantg@cpan.org>',
    LICENSE             => 'perl',

    PREREQ_PM => {
        'Config::General'       => 0,           # MyBase.pm
        'Contextual::Return'    => 0,           # For send_friend_request method
        'Crypt::SSLeay'         => 0.53,        # WWW::Mechanize, for SSL access
                                                #  to myspace.com
        'File::Spec::Functions' => 0,           # Note: Forces File::Spec 0.7 or
                                                #  later.
        'Locale::SubCountry'    => 1.38,        # FriendAdder.pm,
                                                #  cool_new_people
        'Params::Validate'      => 0,           # MyBase.pm
        'Spiffy'                => 0.24,
        'Time::ParseDate'       => 100.010301,  # Myspace.pm - last_login method
        'URI::Escape'           => 0,           # Myspace.pm - find_friend
                                                #  method
        'WWW::Mechanize'        => 1.20,        # Myspace.pm
        'YAML'                  => 0.39,

        # This is actually only a build dependency
        'Test::More'            => 0
    },

    # MakeMaker arguments
    PL_FILES            => {},
    EXE_FILES           => [qw( scripts/approve_friends
                                scripts/comment_myspace
                                scripts/message_group
                              )],
#    (MM->can('signature_target') ? (SIGN => 1) : ()),

    # Parameters for Makefile targets
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Myspace-*' }
);
