#!/usr/bin/env perl

use strict;
use warnings;

use IPC::Open3;
use File::Basename;
use Config;


use Test::More ;
use Test::More ($] < 5.022 ? (skip_all =>
        'Need perl 5.22 or higher to run these tests') : '');

use Warnings::Version '5.22';


my $prefix       = dirname $0;
my $name         = "Warnings/Version.pm";
my $inc          = $INC{$name}; $inc =~ s/\Q$name\E$//;
my $perl_interp  = $^X;
my $perl_version = Warnings::Version::massage_version($]);

my %warnings = (
    experimental__bitwise => qr/^\QThe bitwise feature is experimental\E/,
    experimental__const_attr => qr/^\Q:const is experimental\E/,
    experimental__re_strict => qr/^\Q"use re 'strict'" is experimental\E/,
    experimental__refaliasing => qr/^\QAliasing via reference is experimental\E/,
    experimental__win32_perlio => 'No win32 to test on',
    locale => sub {
        $^O eq 'MSWin32' ?
            "locale test not implemented on MSWin32" :
            qr/^\QUse of \b{} or \B{} for non-UTF-8 locale is wrong.  Assuming a UTF-8 locale\E/;
    },
    missing => qr/^\QMissing argument in sprintf\E/,
    redundant => qr/^\QRedundant argument in sprintf\E/,
);

check_warnings(keys %warnings);

sub check_warnings {
    foreach my $warning (@_) {
        SKIP: {
            skip "Warning $warning not implemented", 1 unless exists
                                                       $warnings{$warning};
            if (ref $warnings{$warning} eq 'CODE') { $warnings{$warning} = $warnings{$warning}->(); }
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
