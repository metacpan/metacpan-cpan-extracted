#!/usr/bin/env perl

use strict;
use warnings;

use IPC::Open3;
use File::Basename;
use Config;


use Test::More ;
use Test::More ($] < 5.008 ? (skip_all =>
        'Need perl 5.8 or higher to run these tests') : '');

use Warnings::Version '5.8';


my $prefix       = dirname $0;
my $name         = "Warnings/Version.pm";
my $inc          = $INC{$name}; $inc =~ s/\Q$name\E$//;
my $perl_interp  = $^X;
my $perl_version = Warnings::Version::massage_version($]);

my %warnings = (
    layer   => qr/^(perlio:\ a|A)\Qrgument list not closed for \E(PerlIO
        \ )?\Qlayer "encoding(UTF-8"\E/x,
    threads => qr/^\Qcond_broadcast can only be used on shared values\E/,
);

check_warnings(qw/ layer /);

SKIP: {
    skip "Not running on a threaded perl", 1 unless $Config{usethreads};

    check_warnings(qw/ threads /);
};

sub check_warnings {
    foreach my $warning (@_) {
        SKIP: {
            skip "Warning $warning not implemented", 1 unless exists
                                                       $warnings{$warning};
            skip $warnings{$warning}, 1 unless ref $warnings{$warning}
                                                               eq 'Regexp';

            like( get_warning("10-helpers/$warning.pl"),
                $warnings{$warning}, "$warning warnings works ($^X)" );
        };
    }
}

sub get_warning {
    my $script = "$prefix/$_[0]";
    if (not -f $script) {
        fail("Warning script not found: $script");
        return "Error: No such file: $script";
    }
    my $pid = open3(\*IN, \*OUT, \*ERR, $perl_interp, "-I$inc", "$script");
    my $foo = <ERR>;
    $foo = "" unless defined $foo;
    chomp($foo);
    waitpid($pid, 0);
    close IN;
    close OUT;
    close ERR;

    return $foo;
}

done_testing;
