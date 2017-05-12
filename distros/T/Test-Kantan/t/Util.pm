package t::Util;
use strict;
use warnings;
use utf8;
use 5.010_001;
use Test::More;

use parent qw(Exporter);

our @EXPORT = qw(run_test slurp_utf8 spew_utf8 slurp spew);

{
    # utf8 hack.
    binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;                       
    no warnings 'redefine';
    my $code = \&Test::Builder::child;
    *Test::Builder::child = sub {
        my $builder = $code->(@_);
        binmode $builder->output,         ":utf8";
        binmode $builder->failure_output, ":utf8";
        binmode $builder->todo_output,    ":utf8";
        return $builder;
    };
}

sub run_test {
    my $path = shift;

    my ($tmp, $filename) = File::Temp::tempfile(UNLINK => 1);
    close $tmp;

    my $pid = fork;
    die $! unless defined $pid;
    if ($pid) {
        waitpid($pid, 0);

        open my $fh, '<:encoding(utf-8)', $filename or die $!;
        my $out = do { local $/; <$fh> };
        close $fh;

        return $out;
    } else {
        # child
        open(STDOUT, ">", $filename) or die "Cannot redirect";
        open(STDERR, ">", $filename) or die "Cannot redirect";
        exec $^X, '-Ilib', $path;
        die "Cannot exec";
    }
}

sub slurp_utf8 {
    my $fname = shift;
    open my $fh, '<:encoding(utf-8)', $fname
        or Carp::croak("Can't open '$fname' for reading: '$!'");
    scalar(do { local $/; <$fh> })
}

sub slurp {
    my $fname = shift;
    open my $fh, '<', $fname
        or Carp::croak("Can't open '$fname' for reading: '$!'");
    scalar(do { local $/; <$fh> })
}

sub spew {
    my $fname = shift;
    open my $fh, '>', $fname
        or Carp::croak("Can't open '$fname' for writing: '$!'");
    print {$fh} $_[0];
}

sub spew_utf8 {
    my $fname = shift;
    open my $fh, '>:encoding(utf-8)', $fname
        or Carp::croak("Can't open '$fname' for writing: '$!'");
    print {$fh} $_[0];
}

1;

