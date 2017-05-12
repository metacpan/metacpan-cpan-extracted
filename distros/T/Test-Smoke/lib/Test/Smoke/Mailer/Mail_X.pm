package Test::Smoke::Mailer::Mail_X;
use warnings;
use strict;

use base 'Test::Smoke::Mailer::Base';

=head1 Test::Smoke::Mailer::Mail_X

This handles sending the message with either the B<mail> or B<mailx> program.

=head1 DESCRIPTION

=head2 Test::Smoke::Mailer::Mail_X->new( %args )

Keys for C<%args>:

  * ddir
  * mailbin/mailxbin
  * to
  * cc
  * v

=cut

=head2 $mailer->mail( )

C<mail()> sets up the commandline and body and pipes it to either the
B<mail> or the B<mailx> program.

=cut

sub mail {
    my $self = shift;

    my $mailer = $self->{mailbin} || $self->{mailxbin};

    my $subject = $self->fetch_report();
    my $cc = $self->_get_cc( $subject );

    my $cmdline = qq|$mailer -s '$subject'|;
    $self->{swcc}  ||= '-c', $cmdline   .= qq| $self->{swcc} '$cc'| if $cc;
    $self->{swbcc} ||= '-b', $cmdline   .= qq| $self->{swbcc} '$self->{bcc}'|
        if $self->{bcc};
    $cmdline   .= qq| $self->{to}|;

    $self->{v} > 1 and print "[$cmdline]\n";
    $self->{v} and print "Sending report to $self->{to} ";
    local *MAILER;
    if ( open MAILER, "| $cmdline " ) {
        print MAILER $self->{body};
        close MAILER or
            $self->{error} = "Error in pipe to '$mailer': $! (" . $?>>8 . ")";
    } else {
        $self->{error} = "Cannot fork '$mailer': $!";
    }
    $self->{v} and print $self->{error} ? "not OK\n" : "OK\n";

    return ! $self->{error};
}

1;

=head1 COPYRIGHT

(c) 2002-2013, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
