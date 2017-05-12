#!perl
#
# This file is part of Time::Fuzzy.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Time::Fuzzy',
    AUTHOR              => 'Jerome Quelin <jquelin@cpan.org>',
    VERSION_FROM        => 'lib/Time/Fuzzy.pm',
    ABSTRACT_FROM       => 'lib/Time/Fuzzy.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::Accessor' => 0,
        'DateTime'        => 0,
        'Test::More'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [
                'Time-Fuzzy-*', 'MANIFEST.bak',
                map { ( '*/' x $_ ) . '*~' } 0..4
        ] },
);
