package Test::Smoke::Mailer::Sendmail;
use warnings;
use strict;

our $VERSION = '0.016';

use base 'Test::Smoke::Mailer::Base';

=head1 Test::Smoke::Mailer::Sendmail

This handles sending the message by piping it to the B<sendmail> program.

=head1 DESCRIPTION

=head2 $mailer->mail( )

C<mail()> sets up a header and body and pipes them to the B<sendmail>
program.

=cut

sub mail {
    my $self = shift;

    my $subject   = $self->fetch_report();
    my $cc = $self->_get_cc( $subject );
    my $header = "To: $self->{to}\n";
    $header   .= "From: $self->{from}\n"
        if exists $self->{from} && $self->{from};
    $header   .= "Cc: $cc\n" if $cc;
    $header   .= "Bcc: $self->{bcc}\n" if $self->{bcc};
    $header   .= "Subject: $subject\n\n";

    $self->{v} > 1 and print "[$self->{sendmailbin} -i -t]\n";
    $self->{v} and print "Sending report to $self->{to} ";
    local *MAILER;
    if ( open MAILER, "| $self->{sendmailbin} -i -t " ) {
        print MAILER $header, $self->{body};
        close MAILER or
            $self->{error} = "Error in pipe to sendmail: $! (" . $?>>8 . ")";
    } else {
        $self->{error} = "Cannot fork ($self->{sendmailbin}): $!";
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
