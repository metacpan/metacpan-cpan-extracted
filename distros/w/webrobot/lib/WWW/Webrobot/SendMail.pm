package WWW::Webrobot::SendMail;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use MIME::Lite;


sub send_mail {
    my ($mail) = @_;
    return 1 if !$mail;

    my $server = $mail -> {server} or die "No mail server given";
    my $timeout = $mail -> {timeout} || 60;
    my %parm = ( %$mail );
    delete @parm{qw(condition server timeout)};
    my $msg = MIME::Lite -> new(%parm);
    my $msg_to = $msg->get("to");
    my $msg_cc = $msg->get("cc");
    my $msg_bcc = $msg->get("bcc");
    foreach (@{$mail->{Attach}}) {
        my ($mime, $filename) = @$_;
        $mime ||= "application/octet-stream";
        $msg->attach(Type=>$mime, Path=>$filename);
    }
    MIME::Lite -> send('smtp', $server, Timeout=>$timeout);
    eval { $msg -> send() };
    if ($@) {
        print STDERR "Can't send mail: $@";
        return $@;
    }
    else {
        print STDERR "Sending mail",
            $msg_to  ? " to: $msg_to" : "",
            $msg_cc  ? " cc: $msg_cc" : "",
            $msg_bcc ? " bcc: $msg_bcc" : "", "\n";
        return 0;
    }
}

1;


=head1 NAME

WWW::Webrobot::SendMail - simple wrapper for sending mail

=head1 SYNOPSIS

 WWW::Webrobot::SendMail::send_mail($mailconfig);

=head1 DESCRIPTION

Function to send mail.
Uses L<MIME::Lite>.


=head1 METHODS

=over

=item send_mail

Function to send mail

 my $mailconfig = {
        server    => "somesever.yourdomain.org", # mandatory
        timeout   => 60, # default=60

        # fields for MIME::Lite, ignores case on left hand side
        'Return-Path' => 'from@domain.de', # defaults to 'From' attribute
        From          => 'webrobot',
        'Reply-To'    => 'reply@domain.de',
        To            => 'to@domain.de',
        Cc            => 'some@other.com, some@more.com',
        Bcc           => 'blind@domain.de',
        Subject       => 'Subject for mail',
        Type          => 'text/plain',
        Encoding      => 'quoted-printable', # 'quoted-printable', 'base64'
        #Path          => 'hellonurse.gif'
        Data          => <<'EOF',
 Thats the body of the
 mail you want to send.
 EOF

C<$exit> acts as an error state thats compared to $mail->{condition}

Return value:

 0:       Mail has been sent. Note that doesn't mean that the mail can be delivered.
 not 0:   Mail can't be sent (e.g. wrong mail server)

=back

=cut
