package Local::Test;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use parent 'XT::Files::Plugin';

sub BUILD {
    my ( $self, $args ) = @_;

    my $report_file = $ENV{REPORT_FILE_BASE};
    die 'Environment variable REPORT_FILE not set' if !defined $report_file;
    $report_file .= '.new';

    open my $fh, '>', $report_file or die "Unable to write file $report_file: $!";
  ARG:
    for my $key ( sort keys %{$args} ) {
        next ARG if $key eq 'xtf';
        print $fh "$key=$args->{$key}\n";
    }
    close $fh or die "Unable to write file $report_file: $!";

    return $self;
}

sub run {
    my ( $self, $args ) = @_;

    my $report_file = $ENV{REPORT_FILE_BASE};
    die 'Environment variable REPORT_FILE not set' if !defined $report_file;
    $report_file .= '.run';

    open my $fh, '>', $report_file or die "Unable to write file $report_file: $!";
    for my $arg ( @{$args} ) {
        my ( $key, $value ) = @{$arg};
        print $fh "$key=$value\n";
    }
    close $fh or die "Unable to write file $report_file: $!";

    return;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
