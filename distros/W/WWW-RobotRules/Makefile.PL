#!perl -w

require 5.008001;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'WWW::RobotRules',
    VERSION_FROM => 'lib/WWW/RobotRules.pm',
    ABSTRACT_FROM => 'lib/WWW/RobotRules.pm',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    LICENSE => "perl",
    MIN_PERL_VERSION => 5.008001,
    PREREQ_PM => {
        'AnyDBM_File' => 0,
        'Fcntl' => 0,
        'URI' => "1.10",
    },
    META_MERGE => {
	resources => {
            repository => 'http://github.com/gisle/www-robotrules',
	    MailingList => 'mailto:libwww@perl.org',
        }
    },
);


BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f ".gitignore";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}
