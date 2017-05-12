#!/usr/bin/env perl

use strict;
use warnings;

use IPC::Open3;
use File::Basename;
use Config;


use Test::More (($] < 5.006) ? (skip_all =>
        'Need perl 5.6 or higher to run these tests') : '');

use Warnings::Version '5.6';



my $prefix       = dirname $0;
my $name         = "Warnings/Version.pm";
my $inc          = $INC{$name}; $inc =~ s/\Q$name\E$//;
my $perl_interp  = $^X;
my $perl_version = Warnings::Version::massage_version($]);

my %warnings = (
    chmod => qr/^\Qchmod() mode argument is missing initial 0/,
    umask => qr/^\Qumask: argument is missing initial 0/,
    y2k   => qr/^\QPossible Y2K bug: about to append an integer to '19'/,
);

SKIP: {
    skip "Chmod and umask warning categories only exist on perl 5.6", 2
        unless $perl_version eq '5.6';
    check_warnings(qw/ chmod umask /);
};

SKIP: {
    skip "Y2K warnings only exist on perls 5.6 and 5.8", 1
        unless grep { $perl_version eq $_ } qw/ 5.6 5.8 /;
    skip "Only run this test if perl has been built with Y2K warnings enabled"
        , 1 unless $Config{ccflags} =~ /Y2KWARN/;

    check_warnings(qw/ y2k /);
};

sub check_warnings {
    for my $warning (@_) {
        SKIP: {
            skip "Warning $warning not implemented", unless exists
                                                       $warnings{$warning};
            skip $warnings{$warning}, 1 unless ref $warnings{$warning}
                                                                   eq 'Regexp';

            like( get_warning("10-helpers/$warning.pl"),
                $warnings{$warning}, "$warning warning works ($^X)" );
        }
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
