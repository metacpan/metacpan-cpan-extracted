package Test::Nightly::Email;

use strict;
use warnings;

use Carp;
use Email::Send;
use Email::Simple;
use Email::Simple::Creator;

use base qw(Test::Nightly::Base Class::Accessor::Fast);

my @methods = qw(
	smtp_server
	to           
	cc           
	bcc          
	from         
	subject      
	content_type 
	mailer       
	message      
	smtp_server
);

__PACKAGE__->mk_accessors(@methods);

our $VERSION = '0.03';

=head1 NAME

Test::Nightly::Email - Emails reports, errors etc.

=head1 DESCRIPTION

Package that uses the Email::* modules to mail reports and error notifications. Use this module to set up your email configuration. You probably should not be dealing with this directly.

=head1 SYNOPSIS

  my $email = Test::Nightly::Email->new({
    to => 'kirstinbettiol@gmail.com',
  });

  $email->send({
    subject => 'Your Test Report',
    message => 'All your tests failed!'
  });

=cut

=head2 new()

  my $email = Test::Nightly::Email->new({
    to           => 'kirstinbettiol@gmail.com',  # Required
    cc           => 'kirstinbettiol@gmail.com',
    bcc          => 'kirstinbettiol@gmail.com',
    from         => 'kirstinbettiol@gmail.com',
    subject      => 'The results of your test',
    content_type => 'text/html',                 # Defaults 'text/html' 
    mailer       => 'Sendmail',                  # 'SMTP' || 'Qmail'. Defaults to 'Sendmail'
    message      => 'The body of the email',
    smtp_server  => 'smtp.yourserver.com',       # Required if you specify SMTP as your mailer.
  });

The constructor to create the new email object. 

=cut

sub new {

    my ($class, $conf) = @_;

	my $self = bless {}, $class;

	$self->_init($conf, \@methods);

	return $self;

}

=head2 send()

  $email->send({
    ... takes the same arguments as new ...
  });

Sends the email.

=cut

sub email {

    my ($self, $conf) = @_;

	$self->_init($conf, \@methods);
	
	$self->content_type('text/html') 	unless defined $self->content_type();
	$self->mailer('Sendmail')		 	unless defined $self->mailer();

	unless (defined $self->to()) {
		return;
	}

	my %header = (
		'To'           => $self->to(),
		'Cc'           => $self->cc(),
		'Bcc'          => $self->bcc(),
		'From'         => $self->from(),
		'Subject'      => $self->subject(),
		'Content-Type' => $self->content_type(),
	);

	my $email = Email::Simple->create(
		header => [%header],
		body   => $self->message(),
	);

	if ($self->mailer() =~ /Sendmail/i) {

		send Sendmail => $email;

	} elsif ($self->mailer() =~ /SMTP/i) {

		if (defined $self->smtp_server()) {

			send SMTP => $email, $self->smtp_server();

		} 

	} elsif ($self->mailer() =~ /Qmail/i) {

		send Qmail => $email;

	}

}

=head1 List of methods:

=over 4

=item to

The email "To" field. Takes a comma separated list of emails. Required.

=item cc

The email "Cc" field. Takes a comma separated list of emails.

=item bcc

The email "Bcc" field. Takes a comma separated list of emails.

=item from

The email "from" field.

=item subject

The subject line of the email

=item content_type
  
The Content-type you wish the email to be. Defaults to 'text/html'.

=item mailer

The mailer you wish to use. Currently supports 'Sendmail' || 'SMTP' || 'Qmail'. Defaults to 'Sendmail'

=item message

The body of the email.

=item smtp_server

If you specify SMTP as your mailer then you are required to specify this.

=back

=head1 AUTHOR

Kirstin Bettiol <kirstinbettiol@gmail.com>

=head1 COPYRIGHT

(c) 2005 Kirstin Bettiol
This library is free software, you can use it under the same terms as perl itself.

=head1 SEE ALSO

L<Email::Send>, 
L<Email::Simple>, 
L<Email::Simple::Creator>, 
L<Email::Send::Qmail>, 
L<Email::Send::SMTP>, 
L<Email::Send::Sendmail>, 
L<Test::Nightly>, 
L<Test::Nightly::Test>, 
L<Test::Nightly::Report>, 
L<Test::Nightly::Email>, 
L<perl>.

=cut

1;

