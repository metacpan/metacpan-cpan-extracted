# Tom Moertel <tom@moertel.com>

package CaptureOutput;

use File::Temp qw( tempfile );

=head1 NAME

CaptureOutput - temporarily capture output from a filehandle

=head1 SYNOPSIS

    print STDERR "before capturing\n";
    my $recorder = capture(*STDERR);    # start capturing
    print STDERR "during capturing\n";
    my $recd_output = $recorder->();    # stop & get recording
    print STDERR "after capturing\n";
    print "Recorded output = $recd_output";

=head1 DESCRIPTION

This module exports a single function C<capture> that allows you to
temporarily capture output from a given filehandle.  The function
returns an anonymous function that can be used to restore the
filehandle to its previous condition and return any captured output.

For example, the output of the code in the Synopsis is as follows:

    before redirection
    after redirection
    Saved output = during redirection

=cut

sub import {
    my $caller = caller;
    { no strict 'refs';  *{$caller.'::capture'} = \&capture; }
}

sub capture {

    my $target_fh = shift;
    my $temp_fh   = tempfile();
    my $temp_fd   = fileno $temp_fh;

    local *SAVED;
    local *TARGET = $target_fh;
    open SAVED,  ">&TARGET"     or die "can't remember target: $!";
    open TARGET, ">&=$temp_fd"  or die "can't redirect target: $!";
    my $saved_fh = *SAVED;

    return sub {
        seek $temp_fh, 0, 0 or die "can't seek: $!";  # rewind
        my $captured_output = do { local $/; <$temp_fh> };
        close $temp_fh or die "can't close temp file handle: $!";
        local (*SAVED, *TARGET) = ($saved_fh, $target_fh);
        open TARGET, ">&SAVED"  or die "can't restore target: $!";
        close SAVED             or die "can't close SAVED: $!";
        return $captured_output;
    }
}


1;

=head1 AUTHOR

Tom Moertel (tom@moertel.com)

=head1 COPYRIGHT and LICENSE

Copyright (c) 2004-05 by Thomas G Moertel.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
