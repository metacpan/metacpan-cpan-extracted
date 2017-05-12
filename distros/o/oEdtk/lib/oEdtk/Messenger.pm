package oEdtk::Messenger;

use strict;
use warnings;

use Email::Sender::Simple 	qw(sendmail);
use Email::Sender::Transport::SMTP;
use oEdtk::Config			qw(config_read);

use Exporter;
our $VERSION	= 0.001;
our @ISA	= qw(Exporter);
our @EXPORT_OK	= qw(oe_send_mail);
#http://search.cpan.org/~rjbs/Email-Sender-0.120002/lib/Email/Sender/Manual/QuickStart.pm

sub oe_send_mail {
	my ($to, $subject, @body) = @_;
	my $cfg = config_read('MAIL');
	$subject ||=$0;
	$subject = $cfg->{'EDTK_TYPE_ENV'} . " - $subject ";

	my $transport = Email::Sender::Transport::SMTP->new({
		host => $cfg->{'EDTK_MAIL_SMTP'}
	});
	
	my $email = Email::Simple->create(
		header => [
			To	=> $to 		|| $cfg->{'EDTK_MAIL_SENDER'}, 
			From	=> $cfg->{'EDTK_MAIL_SENDER'}, 
			Subject	=> $subject 	|| $0
		],
		body => join('', @body)
	);
	
	# Useful for testing.
	if ($cfg->{'EDTK_MAIL_SMTP'} eq 'warn') {
		print $email->as_string() . "\n" ;
	} else {
		eval { sendmail($email, { transport => $transport }); } ;
		if ($@) {
			die "ERROR: sendmail failed. Reason is $@\n";
		}
	}
}
