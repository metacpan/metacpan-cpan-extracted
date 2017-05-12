package WebService::VerifyEmail;
$WebService::VerifyEmail::VERSION = '0.03';
use 5.006;
use Moo;
use Net::HTTP::Tiny qw(http_get);
use JSON qw(decode_json);
use WebService::VerifyEmail::Response;

has username => (is => 'ro');
has password => (is => 'ro');

sub email_ok
{
    my $self          = shift;
    my $email_address = shift;
    my $response      = $self->check_email($email_address);

    return $response->verify_status eq '1' ? 1 : 0;
}

sub check_email
{
    my $self          = shift;
    my $email_address = shift;

    my $url = sprintf("http://api.verify-email.org/api.php?usr=%s&pwd=%s&check=%s",
                   $self->username,
                   $self->password,
                   $email_address);
    return WebService::VerifyEmail::Response->new( decode_json( http_get($url) ) );
}

1;

=head1 NAME

WebService::VerifyEmail - check validity of an email address using verify-email.org

=head1 SYNOPSIS

  use WebService::VerifyEmail;
  
  my $verifier = WebService::VerifyEmail->new(
                    username => $username,
                    password => $password,
                    );
  
  print "Email is ", $verifier->email_ok($email)
                     ? 'GOOD'
                     : 'BAD', "\n";

=head1 DESCRIPTION

WebService::VerifyEmail is an interface to the service at
L<verify-email.org|http://verify-email.org> which is used to check
whether an email address is bad.

The simplest way to use this module is the example given in the SYNOPSIS above.
The module also provides a C<check_email()> method, which returns an object
with more information:

  $response = $verifier->check_email($email);
  if ($response->verify_status) {
     print "$email is GOOD\n";
  } else {
     print "$email is BAD:\n",
           "  auth status:  ", $response->authentication_status, "\n",
           "  limit status: ", $response->limit_status, "\n",
           "  limit desc:   ", $response->limit_desc, "\n",
           "  verify desc:   ", $response->verify_status_desc, "\n";
  }

The C<verify_status> field is B<1> if the email address is good,
and C<0> if the email address is bad (caveat: see L<KNOWN BUGS>).
I'm not sure about the other fields at the moment, but when I've had
clarification, I'll update this documentation :-)

verify-email.org is a commercial service: there is a free level,
but you can only check a small number of email addresses with that.
You'll have to pay if you want to check any serious
number of email addresses.

=head1 KNOWN BUGS

You can get false positives from the service: an email address can
be reported as good, but then when you try and send email to it, you get a bounce.
That's just the reality of the email infrastructure.

=head1 SEE ALSO

The following modules provide some form of checking of email addresses,
from basic format checks upwards.

L<Mail::VRFY>, L<Mail::Verify>, L<Email::Valid>, L<String::Validator::Email>,
L<Mail::CheckUser>, L<Mail::EXPN>, L<Net::validMX>, L<Email::Valid::Loose>.

=head1 REPOSITORY

L<https://github.com/neilb/WebService-VerifyEmail>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


