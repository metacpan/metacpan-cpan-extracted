#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'WWW::UsePerl::Journal::Thread',
    VERSION_FROM        => 'lib/WWW/UsePerl/Journal/Thread.pm',
    ABSTRACT            => 'Handles the retrieval of UsePerl journal comment threads',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'Class::Accessor::Fast'     => 0,
        'HTTP::Request::Common'     => 0,
        'LWP::UserAgent'            => 0,
        'Time::Piece'               => 1.07,
		'WWW::UsePerl::Journal'     => 0.22,

        # build/test prereqs
        'IO::File'                  => 0,
        'Test::Exception'           => 0,
		'Test::More'                => 0.70,

    }
);
