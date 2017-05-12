#---------------------------------------------------------------------
package WebService::Google::Voice::SendSMS;
#
# Copyright 2013 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 29 Jan 2013
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Send a SMS using Google Voice
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

use Carp ();
use LWP::UserAgent 6 ();
use HTTP::Request::Common ();

#use Smart::Comments '###';

our $VERSION = '1.002';
# This file is part of WebService-Google-Voice-SendSMS 1.002 (February 21, 2015)

#=====================================================================

sub formURL { 'https://www.google.com/voice/m/sms' }
sub loginURL { 'https://www.google.com/accounts/ClientLogin' }
sub smsURL   { 'https://www.google.com/voice/m/sendsms' }
#---------------------------------------------------------------------


sub new
{
  my ($class, $username, $password) = @_;

  bless {
    username => $username,
    password => $password,
    ua       => LWP::UserAgent->new(
      agent => "Mozilla/5.0 (iPhone; U; CPU iPhone OS 2_2_1 like Mac OS X;".
               " en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) ".
               "Version/3.1.1 Mobile/5H11 Safari/525.20",
      cookie_jar => {},
    ),
  }, $class;
} # end new

#---------------------------------------------------------------------
# Get and return the Google authorization credential
#
# Called automatically by _make_request when needed

sub _login
{
  my $self = shift;

  my $rsp = $self->_make_request(
    HTTP::Request::Common::POST($self->loginURL, [
      accountType => 'GOOGLE',
      Email       => $self->{username},
      Passwd      => $self->{password},
      service     => 'grandcentral',
      source      => 'org.cpan.WebService.Google.Voice.SendSMS',
    ]),
    { no_headers => 1 }    # Can't add authorization, we're logging in
  );

  my $cref = $rsp->decoded_content(ref => 1);
  $$cref =~ /Auth=([A-z0-9_-]+)/
      or Carp::croak("SendSMS: Unable to find Auth in response");

  return $1;
} # end _login

#---------------------------------------------------------------------
# Send a request via our UA and return the response:
#
# Options may be passed in $args hashref:
#   allow_failure:  if true, do not die if request is unsuccessful
#   no_headers:     if true, omit Authorization & Referer headers

sub _make_request
{
  my ($self, $req, $args) = @_;

  unless ($args->{no_headers}) {
    $req->header(Authorization =>
                 'GoogleLogin auth=' . ($self->{login_auth} ||= $self->_login));
    $req->referer($self->{lastURL});
  }

  ### Request : $req->as_string
  my $rsp = $self->{ua}->request($req);
  ### Response : $rsp->as_string

  if ($rsp->is_success) {
    $self->{lastURL} = $rsp->request->uri;
  } else {
    Carp::croak("SendSMS: HTTP request failed: " . $rsp->status_line)
        unless $args->{allow_failure};
  }

  $rsp;
} # end _make_request


#---------------------------------------------------------------------
# Fetch the XSRF token from Google Voice

sub _get_rnr_se
{
  my $self = shift;

  my $rsp = $self->_make_request(HTTP::Request::Common::GET($self->formURL));

  my $cref = $rsp->decoded_content(ref => 1);
  $$cref =~ /<input[^>]*?name="_rnr_se"[^>]*?value="([^"]*)"/s
      or Carp::croak("SendSMS: Unable to find _rnr_se in response");

  return $1;
} # end _get_rnr_se
#---------------------------------------------------------------------


sub send_sms
{
  my ($self, $number, $message) = @_;

  my $req = HTTP::Request::Common::POST($self->smsURL, [
    id      => '',
    c       => '',
    number  => $number,
    smstext => $message,
    _rnr_se => $self->_get_rnr_se,
  ]);

  return $self->_make_request($req, { allow_failure => 1 })->is_success;
} # end send_sms

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

WebService::Google::Voice::SendSMS - Send a SMS using Google Voice

=head1 VERSION

This document describes version 1.002 of
WebService::Google::Voice::SendSMS, released February 21, 2015.

=head1 SYNOPSIS

  use WebService::Google::Voice::SendSMS;

  my $sender = WebService::Google::Voice::SendSMS->new(
    $email_address, $password
  );

  $sender->send_sms($phone_number => $message);

=head1 DESCRIPTION

WebService::Google::Voice::SendSMS allows you to send SMS messages
using your Google Voice account (L<https://www.google.com/voice>).
It only works if you're able to send SMS messages from the Google
Voice website. There should be a TEXT button next to the CALL button
in the upper left corner. If that doesn't work, then SendSMS won't
work either.

=head1 METHODS

=head2 new

  $s = WebService::Google::Voice::SendSMS->new($username, $password);

Create a new SendSMS object.  This does not perform any network
request.  Pass the C<$username> (e.g. C<your.name@gmail.com>) and
C<$password> you use to login to your Google Voice account.


=head2 send_sms

  $success = $s->send_sms($phone_number, $message);

Send an SMS saying C<$message> to C<$phone_number>.  The SMS will be
sent by your Google Voice phone number.  C<$success> is true if the
message was accepted by Google Voice (which does not necessarily mean
that it was successfully delivered to the intended recipient).

=head1 SEE ALSO

L<Google::Voice> is a much more complete API for Google Voice.
However, I was unable to get it to login successfully.

WebService::Google::Voice::SendSMS is heavily based on
L<http://code.google.com/p/phpgooglevoice/> by LostLeon.  It started
life as a Perl translation of the PHP code, but it's been refactored
substantially since then.

=head1 DIAGNOSTICS

=over

=item C<< SendSMS: HTTP request failed: %d %s >>

This indicates that we received an HTTP error after sending a request
to Google.  The HTTP status code and message are included.  The most
common error is C<403 Forbidden>, which indicates that you've used the
wrong username or password.


=item C<< SendSMS: Unable to find %s in response >>

This indicates that the response we got from Google did not look like
what we expected.  Perhaps Google has changed their website.  Look for
an updated version of WebService::Google::Voice::SendSMS.  If no
update is available, report a bug.


=back

=head1 CONFIGURATION AND ENVIRONMENT

WebService::Google::Voice::SendSMS uses L<LWP::UserAgent> for sending
requests to Google Voice, so it's influenced by the environment
variables that configure that (especially the SSL options).

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

WebService::Google::Voice::SendSMS can only send SMS messages. It
can't receive them, retrieve the history of sent messages, or access
any other Google Voice features.

=head2 Troubleshooting

If WebService::Google::Voice::SendSMS doesn't work for you, the first
thing to check is that you can send a SMS message by logging in to the
Google Voice website in your browser.  If that doesn't work, you'll
have to try to work the problem out with Google.

If you're getting a HTTP 403 (Forbidden) error, then you may have
supplied the wrong username or password.  If those are correct, you
may need to log in to your Google account and enable "Access for less
secure apps".  To do that, go to L<https://google.com>, log in if
necessary, click your username in the upper right corner, click
Account, click Security, and make sure it says Enabled next to "Access
for less secure apps".  If it doesn't, click Settings and change it.
(If anyone knows how this module can use a more secure login method,
I'd be happy to hear about it.)

If it's still not working, please install the L<Smart::Comments> module,
uncomment the C<use Smart::Comments> line at the beginning of this
module, and include the debugging output in your bug report.  (Be sure
to sanitize your password.)

=for Pod::Coverage
\w+URL

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-WebService-Google-Voice-SendSMS AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=WebService-Google-Voice-SendSMS >>.

You can follow or contribute to WebService-Google-Voice-SendSMS's development at
L<< https://github.com/madsen/webservice-google-voice-sendsms >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
