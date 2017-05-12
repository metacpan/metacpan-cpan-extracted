#!/usr/bin/env perl

use strict;
use warnings;

use IPC::Open3;
use File::Basename;
use Config;


use Test::More ;
use Test::More ($] < 5.020 ? (skip_all =>
        'Need perl 5.20 or higher to run these tests') : '');

use Warnings::Version '5.20';


my $prefix       = dirname $0;
my $name         = "Warnings/Version.pm";
my $inc          = $INC{$name}; $inc =~ s/\Q$name\E$//;
my $perl_interp  = $^X;
my $perl_version = Warnings::Version::massage_version($]);

my %warnings = (
    experimental__autoderef     => qr/^\Qkeys on reference is experimental\E/,
    experimental__lexical_topic => qr/^\QUse of my \E\$\Q_ is experimental\E/,
    experimental__postderef     => qr/^
        \QPostfix dereference is experimental\E
        /x,
    experimental__regex_sets    => qr!^
        \QThe regex_sets feature is experimental in regex; marked by <-- HERE\E
        \Q in m/(?[ <-- HERE  \p{Thai} & \p{Digit} ])/\E
        !x,
    experimental__signatures    => qr/^
        \QThe signatures feature is experimental\E
        /x,
    experimental__smartmatch    => qr/^\QSmartmatch is experimental\E/,
    syscalls                    => qr/^
        \QInvalid \0 character in pathname for open:\E
        /x,
);

check_warnings(keys %warnings);

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
