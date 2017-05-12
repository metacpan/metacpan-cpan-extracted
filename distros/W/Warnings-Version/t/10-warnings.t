#!/usr/bin/env perl

use strict;
use warnings;

use IPC::Open3;
use File::Basename;
use Config;


use Test::More;

# 1
BEGIN { use_ok( 'Warnings::Version', 'all' ); }



my $prefix       = dirname $0;
my $name         = "Warnings/Version.pm";
my $inc          = $INC{$name}; $inc =~ s/\Q$name\E$//;
my $perl_interp  = $^X;
my $perl_version = Warnings::Version::massage_version($]);

my %warnings = (
    closure   => qr/^(
        \QVariable "\E\$\Qfoo" may be unavailable\E
            |
        \QVariable "\E\$\Qfoo" will not stay shared\E
        )/x,
    exiting   => qr/^\QExiting eval via last/,
    io        => qr/^Filehandle (main::)?STDIN opened only for input/,
    glob      => "Not sure how to cause a glob category warning",
    closed    => qr/^\Qreadline() on closed filehandle \E(main::)?STDIN/,
    exec      => qr/^\QStatement unlikely to be reached/,
    newline   => qr/^\QUnsuccessful stat on filename containing newline/,
    pipe      => qr/^\QMissing command in piped open/,
    unopened  => qr/^(
        \Qclose() on unopened filehandle FOO\E
            |
        \QClose on unopened file <FOO>\E)/x,
    misc      => qr/^\QOdd number of elements in hash assignment/,
    numeric   => qr/^\QArgument "foo" isn't numeric in repeat (x)/,
    once      => qr/^\QName "main::foo" used only once: possible typo/,
    overflow  => qr/^\QInteger overflow in hexadecimal number/,
    pack      => qr/^\QAttempt to pack pointer to temporary value/,
    portable  => qr/^\QHexadecimal number > 0xffffffff non-portable/,
    recursion => qr/^\QDeep recursion on subroutine "main::foo"/,
    redefine  => qr/^\QSubroutine foo redefined/,
    regexp    => qr!^(
        \QFalse [] range "a-\d" in regex; marked by <-- HERE in m/[a-\d <-- \E
        \QHERE ]/\E
              |
        \Q/[a-\d]/: false [] range "a-\d" in regexp\E
              |
        \QFalse [] range "a-\d" before HERE mark in regex m/[a-\d << HERE ]/\E
        )!x,
    debugging => "Not sure how to cause a debugging warning",
    inplace   => qr/^Can't open .*nonexistant: /,
    internal  => "Not sure how to cause an internal warning",
    malloc    => "Not sure how to cause a malloc warning",
    signal    => qr/^\QNo such signal: SIGFOOBAR/,
    substr    => qr/^\Qsubstr outside of string\E/,
    syntax    => qr/^\QFound = in conditional, should be ==\E/,
    ambiguous => qr/^
        \QAmbiguous call resolved as CORE::log(), qualify as such or use &\E
        /x,
    bareword  => qr/^\QBareword found in conditional/,
    deprecated => qr/^\Qdefined(\E\@\Qarray) is deprecated\E|^\QCan't use 'defined(\E\@\Qarray)' (Maybe you should just omit the defined()?)\E/,
    digit     => qr/^\QIllegal octal digit '8'\E/, # Since this causes an error
        # we'll clobber it:
    digit     => "Digit warnings seem to be fatal errors rather than warnings",
    parenthesis => qr/^\QParentheses missing around "my" list\E/,
    precedence => qr/^\QPrecedence problem: open FOO should be open(FOO)\E/,
    # Argument "foo" isn't numeric in sprintf
    printf    => qr/^\QInvalid conversion in sprintf: "%A"\E|^\QArgument "foo" isn't numeric in sprintf\E/,
    prototype => qr/^\Qmain::foo() called too early to check prototype\E/,
    qw        => qr/^\QPossible attempt to put comments in qw() list\E/,
    reserved  => qr/^
        \QUnquoted string "bar" may clash with future reserved word\E
        /x,
    semicolon => "Only warns when there's an error anyway",
    taint     => qr/^
        \QInsecure dependency in kill while running with -T switch\E
        /x,
    uninitialized => qr/^
        \QUse of uninitialized value\E(\ \$foo)?\Q in numeric eq (==)\E
        /x,
    unpack    => qr/^(
        \QInvalid type ',' in unpack\E
            |
        \QInvalid type in unpack: ','\E
        )/x,
    untie     => qr/^\Quntie attempted while 1 inner references still exist\E/,
    void      => qr/^(
        \QUseless use of a constant ("foo") in void context\E
            |
        \QUseless use of a constant in void context\E
            |
        \QUseless use of a constant (foo) in void context\E
        )/x,
    utf8      => qr/^\QMalformed UTF-8 character/,
);

my @warnings = Warnings::Version::get_warnings('all', 'all');
check_warnings(@warnings);

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
