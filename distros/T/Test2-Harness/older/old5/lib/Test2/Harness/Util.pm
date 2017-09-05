package Test2::Harness::Util;
use strict;
use warnings;

use Carp qw/confess/;
use Importer Importer => 'import';

use Test2::Util qw/try_sig_mask do_rename/;

our @EXPORT_OK = qw{
    top_file
    read_file
    write_file
    write_file_atomic
    open_file
    close_file
    maybe_open_file
    maybe_top_file
    file_stamp
};

sub read_file {
    my ($file) = @_;

    my $fh = open_file($file);
    local $/;
    my $out = <$fh>;
    close_file($fh, $file);

    return $out;
}

sub top_file {
    my ($file) = @_;

    my $fh = open_file($file);
    my $out = <$fh>;
    close_file($fh, $file);

    return $out;
};

sub maybe_top_file {
    my ($file) = @_;
    return undef unless -f $file;
    return top_file($file);
}

sub write_file {
    my ($file, @content) = @_;

    my $fh = open_file($file, '>');
    print $fh @content;
    close_file($fh, $file);

    return @content;
};

sub open_file {
    my ($file, $mode) = @_;
    $mode ||= '<';
    open(my $fh, $mode, $file) or confess "Could not open file '$file' ($mode): $!";
    return $fh;
}

sub maybe_open_file {
    my ($file, $mode) = @_;
    return undef unless -f $file;
    return open_file($file, $mode);
}

sub close_file {
    my ($fh, $name) = @_;
    return if close($fh);
    confess "Could not close file: $!" unless $name;
    confess "Could not close file '$name': $!";
}

sub write_file_atomic {
    my ($file, @content) = @_;

    my $pend = "$file.pend";

    my ($ok, $err) = try_sig_mask {
        write_file($pend, @content);
        my ($ren_ok, $ren_err) = do_rename($pend, $file);
        die $ren_err unless $ren_ok;
    };

    die $err unless $ok;

    return @content;
}

sub file_stamp {
    my $file = shift;
    my @stat = stat($file);
    return $stat[9];
}


1;
