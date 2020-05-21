package Test::Smoke::Mailer::Mail_Sendmail;
use warnings;
use strict;

our $VERSION = '0.016';

use base 'Test::Smoke::Mailer::Base';

=head1 Test::Smoke::Mailer::Mail_Sendmail

This handles sending the message using the B<Mail::Sendmail> module.

=head1 DESCRIPTION

=head2 Test::Smoke::Mailer::Mail_Sendmail->new( %args )

Keys for C<%args>:

  * ddir
  * mserver
  * to
  * from
  * cc
  * v

=cut

=head2 $mailer->mail( )

C<mail()> sets up the message to be send by B<Mail::Sendmail>.

=cut

sub mail {
    my $self = shift;

    eval { require Mail::Sendmail; };

    $self->{error} = $@ and return undef;

    my $subject = $self->fetch_report();
    my $cc = $self->_get_cc( $subject );

    my %message = (
        To      => $self->{to},
        Subject => $subject,
        Body    => $self->{body},
    );
    $message{cc}   = $cc if $cc;
    $message{bcc}   = $self->{bcc} if $self->{bcc};
    $message{from} = $self->{from} if $self->{from};
    $message{smtp} = $self->{mserver} if $self->{mserver};

    $message{ 'Content-type' } = qq!text/plain; charset="UTF8"!
        if exists $ENV{LANG} && $ENV{LANG} =~ /utf-?8$/i;

    $self->{v} > 1 and print "[Mail::Sendmail]\n";
    $self->{v} and print "Sending report to $self->{to} ";

    Mail::Sendmail::sendmail( %message ) or
        $self->{error} = $Mail::Sendmail::error;

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
