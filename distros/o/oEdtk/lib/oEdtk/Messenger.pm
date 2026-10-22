package oEdtk::Messenger;

use strict;
use warnings;

use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use oEdtk::Config qw(config_read);

use Exporter;
our $VERSION   = 2.1131;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(oe_send_mail);

#http://search.cpan.org/~rjbs/Email-Sender-0.120002/lib/Email/Sender/Manual/QuickStart.pm

sub oe_send_mail {
	my ( $to, $subject, @body ) = @_;
	my $cfg = config_read('MAIL');
	$subject ||= $0;
	$subject = $cfg->{'EDTK_TYPE_ENV'} . " - $subject ";

	my $transport = Email::Sender::Transport::SMTP->new(
		{
			host => $cfg->{'EDTK_MAIL_SMTP'}
		}
	);

	my $email = Email::Simple->create(
		header => [
			To      => $to || $cfg->{'EDTK_MAIL_SENDER'},
			From    => $cfg->{'EDTK_MAIL_SENDER'},
			Subject => $subject || $0
		],
		body => join( '', @body )
	);

	# Useful for testing.
	if ( $cfg->{'EDTK_MAIL_SMTP'} eq 'warn' ) {
		print $email->as_string() . "\n";
	}
	else {
		eval { sendmail( $email, { transport => $transport } ); };
		if ($@) {
			die "ERROR: sendmail failed. Reason is $@\n";
		}
	}
}

=head1 NAME

oEdtk::Messenger - send a simple notification email

=head1 SYNOPSIS

    use oEdtk::Messenger qw(oe_send_mail);

    oe_send_mail('dest@example.com', 'Job report', "done\n");

=head1 DESCRIPTION

A one-function helper to send a short notification email. The SMTP host and
the sender address come from the C<MAIL> section of the oEdtk configuration
(read through L<oEdtk::Config>), and the subject is prefixed with the current
C<EDTK_TYPE_ENV>.

=head1 FUNCTIONS

=head2 oe_send_mail

    oe_send_mail($to, $subject, @body);

Build and send an email to C<$to> (defaulting to C<EDTK_MAIL_SENDER>) with the
given C<$subject> (prefixed with C<EDTK_TYPE_ENV>, defaulting to C<$0>) and
body. When the configured C<EDTK_MAIL_SMTP> is the literal string C<warn>, the
message is printed instead of being sent, which is convenient for testing.
Dies when the send fails.

=head1 AUTHOR

The oEdtk team.

=cut
