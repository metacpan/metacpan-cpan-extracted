package Test::Smoke::Mailer::MIME_Lite;
use warnings;
use strict;

use base 'Test::Smoke::Mailer::Base';

=head1 Test::Smoke::Mailer::MIME_Lite

This handles sending the message using the B<MIME::Lite> module.

=head1 DESCRIPTION

=head2 Test::Smoke::Mailer::MIME_Lite->new( %args )

Keys for C<%args>:

  * ddir
  * mserver
  * msport
  * msuser
  * mspass
  * to
  * from
  * cc
  * v

=cut

=head2 $mailer->mail( )

C<mail()> sets up the message to be send by B<MIME::Lite>.

=cut

sub mail {
    my $self = shift;

    eval { require MIME::Lite; };

    $self->{error} = $@ and return undef;

    my $subject = $self->fetch_report();
    my $cc = $self->_get_cc( $subject );

    my %message = (
        To      => $self->{to},
        Subject => $subject,
        Type    => "TEXT",
        Data    => $self->{body},
    );
    $message{Cc}   = $cc  if $cc;
    $message{Bcc}   = $self->{bcc} if $self->{bcc};
    $message{From} = $self->{from} if $self->{from};

    if ($self->{mserver}) {
        my %authinfo = ();
        $authinfo{AuthUser} = $self->{msuser} if $self->{msuser};
        $authinfo{AuthPass} = $self->{mspass} if defined $self->{mspass};
        MIME::Lite->send(
            smtp       => $self->{mserver},
            Port       => ($self->{msport} || 25),
            FromSender => $self->{from},
            Debug      => ($self->{v} > 1),
            %authinfo,
        );
    }

    my $ml_msg = MIME::Lite->new( %message );
    $ml_msg->attr( 'content-type.charset' => 'UTF8' )
        if exists $ENV{LANG} && $ENV{LANG} =~ /utf-?8$/i;

    $self->{v} > 1 and print "[MIME::Lite]\n";
    $self->{v} and print "Sending report to $self->{to} ";

    $ml_msg->send or $self->{error} = "Problem sending mail";

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
