package Twilio;

use 5.016;
use warnings;

our $VERSION = '2.002';

# 1.x took named arguments; passed to the 2.x constructor they would become the
# credentials and fail only at the first request, as a 401 from Twilio.
my %IS_V1_ARGUMENT = map { $_ => 1 } qw(sid token trace debug use_threads);

# The client is loaded here, not at compile time, so that "use Twilio" stays cheap.
sub new {
  my ($class, @arguments) = @_;
  if (@arguments && defined $arguments[0] && $IS_V1_ARGUMENT{ $arguments[0] }) {
    require Twilio::Exceptions::ConfigurationException;
    Twilio::Exceptions::ConfigurationException->throw(
          "Twilio->new($arguments[0] => ...) is the 1.x interface; "
        . 'since 2.0 it takes ($username, $password, \%options), like Twilio::Rest::Client->new');
  }
  require Twilio::Rest::Client;
  return Twilio::Rest::Client->new(@arguments);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio - Community Perl library for the Twilio API

=head1 VERSION

Version 2.002

=head1 SYNOPSIS

  use Twilio;

  # Credentials from TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN, or given
  my $client = Twilio->new;
  my $client = Twilio->new($account_sid, $auth_token);
  my $client = Twilio->new($api_key_sid, $api_key_secret, { account_sid => $account_sid });

  # Send an SMS
  my $message = $client->messages->create('+15558675310', {
    from => '+15017122661',
    body => 'Hello from Perl',
  });
  print $message->sid, "\n";

  # Make a call
  my $call = $client->calls->create('+15558675310', '+15017122661', {
    url => 'http://demo.twilio.com/docs/voice.xml',
  });

  # Read a list, 20 at most
  for my $message ($client->messages->read({ to => '+15558675310' }, 20)) {
    print $message->body, "\n";
  }

  # Any other product, by its name and version
  $client->verify->v2->services($service_sid)->verifications->create('+15558675310', 'sms');

  # Errors are exceptions, which read as their message
  my $sent = eval { $client->messages->create($to, { from => $from, body => 'Hi' }) };
  warn "Not sent: $@\n" if !$sent;

  # Reply to an incoming SMS, in the webhook of your number
  use Twilio::TwiML::MessagingResponse;

  my $response = Twilio::TwiML::MessagingResponse->new;
  $response->message('Thanks for your message!');
  print "Content-Type: text/xml\n\n", $response;

=head1 DESCRIPTION

A library for the Twilio API. It follows Twilio's official libraries for PHP,
Python and Node.js closely, so Twilio's documentation and its examples apply to
it.

B<For a guide, read L<Twilio::Manual>.> It follows Twilio's messaging and voice
quickstarts: it sends an SMS, receives and replies to one, makes a call and
answers one, and then covers credentials, webhook validation, lists, errors,
other products, and how to translate any example from Twilio's documentation.

This module only makes the client. C<< Twilio->new >> returns a
L<Twilio::Rest::Client>, where every product starts.

=head1 METHODS

=head2 new

  my $client = Twilio->new($username, $password, \%options);

The same as C<< Twilio::Rest::Client->new >>, with the same arguments, and it returns a
L<Twilio::Rest::Client>. C<$username> and C<$password> are an Account SID and Auth
Token, or an API key and its secret, which then needs C<account_sid> in the options.
With no arguments, the credentials come from the C<TWILIO_ACCOUNT_SID> and
C<TWILIO_AUTH_TOKEN> environment variables. See L<Twilio::Base::BaseClient> for the
options.

Version 1.x took named arguments (C<< sid => ..., token => ... >>). Those are refused with a
L<Twilio::Exceptions::ConfigurationException>, so that old code fails at once instead of
at its first request.

=head1 WHAT IT COVERS

=over

=item * The REST API of Twilio's products: 58 API versions and 577 resources,
generated from Twilio's OpenAPI specifications. Each resource has its own module,
documented with every value it takes, in Twilio's words, such as
L<Twilio::Rest::Api::V2010::Account::Message> for messages.

=item * TwiML for voice, messaging and fax, with every verb and attribute:
L<Twilio::TwiML::VoiceResponse>, L<Twilio::TwiML::MessagingResponse> and
L<Twilio::TwiML::FaxResponse>.

=item * Validation of the requests Twilio sends to your webhooks:
L<Twilio::Security::RequestValidator>.

=item * Access tokens for Twilio's client SDKs, L<Twilio::Jwt::AccessToken>, and
the older capability tokens.

=item * Authentication with the Auth Token, API keys, OAuth client credentials
(L<Twilio::CredentialProvider::ClientCredentialProvider>), and Public Key
Client Validation (L<Twilio::Http::ValidationClient>).

=item * Regions and edges, retries after HTTP 429, paging, file uploads,
detailed errors (L<Twilio::Exceptions::RestException> and its subclasses), and
the status code and headers of each answer (L<Twilio::Metadata>).

=back

=head1 HOW IT FOLLOWS THE OFFICIAL LIBRARIES

It has the structure of Twilio's official libraries, which are generated from the
same specifications: the client, then a product and its version, then the list of
a resource, the context of one record, and the record. Where the official libraries
differ, it follows twilio-php: method names, the order of required values, paging,
and how errors and TwiML are written.

A documentation example becomes Perl with a few rules: names in snake_case,
required values first as plain arguments, optional values in a hash reference, and
C<eval> for errors. L<Twilio::Manual/"TRANSLATING TWILIO'S EXAMPLES"> lists them,
with a PHP and a Python example side by side.

=head1 HOW IT IS BUILT

The modules under C<Twilio::Rest> are generated, as the official libraries' are,
from Twilio's OpenAPI specifications, by a generator that applies the rules of
Twilio's own and decides unclear cases the way twilio-php does. Their documentation
comes from the descriptions in the specifications. The TwiML modules are generated
from the names in twilio-php.

The rest is written by hand: HTTP, authentication, paging, errors, TwiML, tokens and
validation. It is ported from twilio-php, with choices from twilio-python and
twilio-node where those are better. Only requests that Twilio refused with HTTP 429
are ever sent again, so a message is never sent twice.

=head1 HOW IT IS TESTED

=over

=item * Unit tests for every hand-written module, with a fake HTTP client, so they
need no account and no network.

=item * Access tokens, capability tokens, webhook signatures and TwiML are compared
with what twilio-php itself produces.

=item * Each of the 1,563 operations is checked against its specification: its URL,
method, values and their formats, and the reading of every documented answer.

=item * The hand-written tests of twilio-php, twilio-python and twilio-node were
compared case by case with these, and the missing cases added.

=item * Optional live tests call the real API.

=item * Every example in L<Twilio::Manual> is run by the tests.

=item * Continuous integration on Linux, macOS and Windows, with Perl 5.16 and the
latest Perl.

=back

=head1 SEE ALSO

L<Twilio::Manual>, L<Twilio::Rest::Client>, L<Twilio::Base::BaseClient>, and
Twilio's documentation at L<https://www.twilio.com/docs>.

=head1 COMMUNITY LIBRARY

This is an independent, community-maintained library. It is not written,
endorsed or supported by Twilio Inc. "Twilio" is a trademark of Twilio Inc.

=head1 BUGS

Please report bugs at L<https://github.com/Zarabozo/Twilio/issues>.

Report security problems privately, by email, as F<SECURITY.md> in this
distribution explains, not through issues.

=head1 AUTHOR

Francisco Zarabozo <zarabozo@cpan.org>

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo.

This library is free software, released under the MIT License. See the
F<LICENSE> file in this distribution.

Parts of it are based on Twilio's own MIT-licensed work, twilio-php and the
twilio-oai specifications. As that license requires, F<LICENSE> also includes
Twilio's copyright notice for them, as credit.

=cut
