#!/usr/bin/perl

BEGIN { require 5.006; }

use ExtUtils::MakeMaker;

my $PACKAGE = 'Tie::VecArray';
my($PACKAGE_FILE) = $PACKAGE =~ /(?:\::)?([^:]+)$/;
my $LAST_API_CHANGE = 0;

eval {
    eval "require $PACKAGE";
};

unless ($@) { # Make sure we did find the module.
    print <<"CHANGE_WARN" if ${$PACKAGE.'::VERSION'} < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

CHANGE_WARN
}

WriteMakefile(
    NAME            => $PACKAGE,
    VERSION_FROM    => "lib/Tie/VecArray.pm",
    PREREQ_PM       => {
        POSIX           => 0,
        fields          => 0,
        base            => 0,
        'Test::More'    => 0.62,
    },
);
