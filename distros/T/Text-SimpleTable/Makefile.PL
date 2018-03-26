#!/usr/bin/env perl

# Copyright (C) 2005-2010, Sebastian Riedel.

use strict;
use warnings;

use ExtUtils::MakeMaker;

my $mm = $ExtUtils::MakeMaker::VERSION;

# Son, when you participate in sporting events,
# it's not whether you win or lose, it's how drunk you get.
WriteMakefile(
    NAME         => 'Text::SimpleTable',
    VERSION_FROM => 'lib/Text/SimpleTable.pm',
    ABSTRACT     => 'Simple eyecandy ASCII tables',
    AUTHOR       => 'Sebastian Riedel <sri@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                dynamic_config => 0,
                'meta-spec' => {version => 2},
                no_index => {directory => [qw/t/]},
                prereqs => {runtime => {requires => {perl => '5.008001'}}},
                resources => {
                    license => ['http://www.opensource.org/licenses/artistic-license-2.0'],
                    repository => {
                        type => 'git',
                        url => 'http://github.com/marcusramberg/text-simpletable.git',
                        web => 'http://github.com/marcusramberg/text-simpletable',
                    },
                },
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {'ExtUtils::MakeMaker' => 0, 'Test::More' => 0}
);
