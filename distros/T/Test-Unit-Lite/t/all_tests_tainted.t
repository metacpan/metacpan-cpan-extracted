#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

BEGIN { if ($] < 5.008) { print "1..0 # Skip Perl is too old\n"; exit 0 } };

BEGIN {
    if (eval { Devel::Cover->VERSION }) {
        print "1..0 # Skip Tainted mode doesn't work well with Devel::Cover\n";
        exit 0;
    };
};

BEGIN {
    if (eval { require Taint::Runtime }) {
        Taint::Runtime->import('enable');
    }
    else {
        print "1..0 # Skip Taint::Runtime missed\n";
        exit 0;
    };
};

use File::Spec;
use Cwd;

BEGIN {
    unshift @INC, map { /(.*)/; $1 } split(/:/, $ENV{PERL5LIB}) if defined $ENV{PERL5LIB} and ${^TAINT};

    my $cwd = ${^TAINT} ? do { local $_=getcwd; /(.*)/; $1 } : '.';
    unshift @INC, File::Spec->catdir($cwd, 'inc');
    unshift @INC, File::Spec->catdir($cwd, 'lib');
};

use Test::Unit::Lite;

local $SIG{__WARN__} = sub { require Carp; Carp::confess("Warning: ", @_) };

Test::Unit::HarnessUnit->new->start('Test::Unit::Lite::AllTests');
