#!/usr/bin/perl

use 5.010001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile (
    NAME           => "V",
    VERSION_FROM   => "lib/V.pm",
    ABSTRACT_FROM  => "lib/V.pm",
    AUTHOR         => 'H.Merijn Brand <hmbrand@cpan.org>',

    BUILD_REQUIRES => {
	"Test::Simple"   => 0.88,
	"Test::Fatal"    => 0,
	"Test::Warnings" => 0,
	},
    PREREQ_PM => {
	version          => 0.77,
	},

    MIN_PERL_VERSION     => "5.010001",
    LICENSE              => "perl_5",
    META_ADD             => {
	"meta-spec"      => {
	    version      => 2,
	    },
	"resources"      => {
	    homepage     => "https://github.com/Tux/V",
	    repository   => {
		type     => "git",
		url      => "https://github.com/Tux/V.git",
		},
	    bugtracker   => {
		web      => "https://github.com/Tux/V/issues",
		},
	    x_IRC        => 'irc://irc.perl.org/#csv',
	    },
	},
    );

1;

package MY;

sub postamble {
    my $do_xt = (-d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    '	-perl doc/make-doc.pl',
	    ''
	: "";
    join "\n" =>
	$do_xt;
    } # postamble
