package Test::Smoke::Mailer::SendEmail;
use warnings;
use strict;

use base 'Test::Smoke::Mailer::Base';

=head1 Test::Smoke::Mailer::SendEmail

This handles sending the message with the B<sendEmail> program.

=head1 DESCRIPTION

=head2 Test::Smoke::Mailer::SendEmail->new( %args )

Keys for C<%args>:

  * ddir
  * mserver
  * msport
  * msuser
  * mspass
  * sendemailbin
  * to
  * from
  * cc
  * v

=cut

=head2 $mailer->mail( )

C<mail()> sets up the commandline and body and passes it to the
B<sendemail> program.

=cut

sub mail {
    my $self = shift;

    my $mailer = $self->{sendemailbin};

    my $subject = $self->fetch_report();
    my $cc = $self->_get_cc( $subject );

    my $cmdline = qq|$mailer -u "$subject"|;
    $self->{swcc}  ||= '-cc',  $cmdline   .= qq| $self->{swcc} "$cc"| if $cc;
    $self->{swbcc} ||= '-bcc', $cmdline   .= qq| $self->{swbcc} "$self->{bcc}"|
        if $self->{bcc};
    $cmdline   .= qq| -t "$self->{to}"|;
    $cmdline   .= qq| -f "$self->{from}"| if $self->{from};

    if ($self->{mserver}) {
        my $mserver = $self->{mserver};
        if ($self->{msport}) {
            $mserver .= ":$self->{msport}";
        }
        $cmdline .= qq| -s "$mserver"|;
    }

    $cmdline   .= qq| -xu "$self->{msuser}"| if $self->{msuser};
    $cmdline   .= qq| -xp "$self->{mspass}"| if defined $self->{mspass};
    $cmdline   .= qq| -o message-file="$self->{file}"|;

    $self->{v} > 1 and print "[$cmdline]\n";
    $self->{v} and print "Sending report to $self->{to}\n";
    system $cmdline;
    if ($?) {
        $self->{error} = "Error executing '$mailer': " . $?>>8;
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
