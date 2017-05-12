
package ZOOM::IRSpy::Test;

use 5.008;
use strict;
use warnings;

use Scalar::Util;

use Exporter 'import';
our @EXPORT = qw(zoom_error_timeout_update zoom_error_timeout_check); 

=head1 NAME

ZOOM::IRSpy::Test - base class for tests in IRSpy

=head1 SYNOPSIS

 ## To follow

=head1 DESCRIPTION

I<## To follow>

=cut


sub subtests { () }

sub timeout { undef }

sub start {
    my $class = shift();
    my($conn) = @_;

    die "can't start the base-class test";
}


our $max_timeout_errors = $ZOOM::IRSpy::max_timeout_errors;

sub zoom_error_timeout_update {
    my ($conn, $exception) = @_;

    if ($exception =~ /Timeout/i) {
        $conn->record->zoom_error->{TIMEOUT}++;
        $conn->log("irspy_test", "Increase timeout error counter to: " .
                $conn->record->zoom_error->{TIMEOUT});
    }
}

sub zoom_error_timeout_check {
    my $conn = shift;

    if ($conn->record->zoom_error->{TIMEOUT} >= $max_timeout_errors) {
        $conn->log("irspy_test", "Got $max_timeout_errors or more timeouts, give up...");
        return  1;
    }

    return 0;
}

=head1 SEE ALSO

ZOOM::IRSpy

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
