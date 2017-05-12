#!/usr/bin/env perl

use 5.008;
use strict;
use warnings;
use Test::More 0.94;
use Fcntl ':seek';
use Tie::Handle::Filter;

my @unimplemented = qw(readline getc open binmode eof tell read sysread seek);
plan tests => 4 + @unimplemented;

subtest 'no coderef' => sub {
    plan tests => 3;
    my $fh = _open();
    ok eval { _tie($fh); 1 } => 'tie';

    my $expected = 'hello world';
    ok eval { print $fh $expected; 1 } => 'print';

    untie *$fh;
    seek $fh, 0, SEEK_SET
        or die "can't seek to start of anonymous storage: $!";
    my $written = join '', <$fh>;
    is $written, $expected, 'read back' or show $written;
};

subtest 'get method name' => sub {
    plan tests => 2;
    my $fh = _open();
    _tie( $fh, \&_get_tied_method_name_only );
    ok eval { print $fh 'hello world'; 1 } => 'print';
    untie *$fh;
    seek $fh, 0, SEEK_SET
        or die "can't seek to start of anonymous storage: $!";
    my $written = join '', <$fh>;
    is $written, 'PRINT', 'found caller' or show $written;
};

subtest 'explicit syswrite arguments' => sub {
    plan tests => 2;
    my $fh = _open();
    _tie($fh);

    my $input    = 'hello world';
    my $offset   = 6;
    my $expected = substr $input, $offset, 5;
    ok eval { syswrite $fh, $input, length $expected, $offset; 1 },
        'syswrite';

    untie *$fh;
    seek $fh, 0, SEEK_SET
        or die "can't seek to start of anonymous storage: $!";
    my $written;
    sysread $fh, $written, length $expected;

    is $written, $expected, 'read back' or show $written;
};

subtest 'explicit close' => sub {
    plan tests => 1;
    my $fh = _open();
    _tie($fh);
    ok eval { close $fh; 1 }, 'close';
};

TODO: {
    local $TODO = 'unimplemented';
    for my $function_name (@unimplemented) {
        my $fh = _open();
        _tie($fh);

        my $buffer;
        my $eval = "$function_name \$fh"
            . (
              $function_name =~ /^(?:sys)?read$/xms ? ', $buffer, 1'
            : $function_name eq 'seek'              ? ', 0, SEEK_SET'
            :                                         q()
            );

        ok eval { eval $eval or die; 1 } => $function_name
            or explain $eval;
        close $fh;
    }
}

sub _open {
    open my $fh, '+>', undef
        or die "can't create anonymous storage: $!";
    return $fh;
}

sub _tie {
    my $fh = shift;
    tie *$fh, 'Tie::Handle::Filter', *$fh, shift;
}

sub _get_tied_method_name_only {
    my $package    = ( caller 0 )[0];
    my $subroutine = ( caller 1 )[3];
    $subroutine =~ s/^${package}:://;
    return $subroutine;
}
