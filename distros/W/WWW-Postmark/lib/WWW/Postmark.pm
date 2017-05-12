package WWW::Postmark;

# ABSTRACT: API for the Postmark mail service for web applications.

use strict;
use warnings;

use Carp;
use Email::Valid;
use HTTP::Tiny;
use JSON::MaybeXS qw/encode_json decode_json/;
use File::Basename;
use File::MimeInfo;
use MIME::Base64 qw/encode_base64/;

our $VERSION = "1.000001";
$VERSION = eval $VERSION;

my $ua = HTTP::Tiny->new(timeout => 45);

=encoding utf-8

=head1 NAME

WWW::Postmark - API for the Postmark mail service for web applications.

=head1 SYNOPSIS

	use WWW::Postmark;

	my $api = WWW::Postmark->new('api_token');
	
	# or, if you want to use SSL
	my $api = WWW::Postmark->new('api_token', 1);

	# send an email
	$api->send(from => 'me@domain.tld', to => 'you@domain.tld, them@domain.tld',
	subject => 'an email message', body => "hi guys, what's up?");

=head1 DESCRIPTION

The WWW::Postmark module provides a simple API for the Postmark web service,
that provides email sending facilities for web applications. Postmark is
located at L<http://postmarkapp.com>. It is a paid service that charges
according the amount of emails you send, and requires signing up in order
to receive an API token.

You can send emails either through HTTP or HTTPS with SSL encryption. You
can send your emails to multiple recipients at once (but there's a 20
recipients limit). If WWW::Postmark receives a successful response from
the Postmark service, it will return a true value; otherwise it will die.

To make it clear, Postmark is not an email marketing service for sending
email campaigns or newsletters to multiple subscribers at once. It's meant
for sending emails from web applications in response to certain events,
like someone signing up to your website.

Postmark provides a test API token that doesn't really send the emails.
The token is 'POSTMARK_API_TEST', and you can use it for testing purposes
(the tests in this distribution use this token).

Besides sending emails, this module also provides support for Postmark's
spam score API, which allows you to get a SpamAssassin report for an email
message. See documentation for the C<spam_score()> method for more info.

=head1 METHODS

=head2 new( [ $api_token, $use_ssl] )

Creates a new instance of this class, with a Postmark API token that you've
received from the Postmark app. By default, requests are made through HTTP;
if you want to send them with SSL encryption, pass a true value for
C<$use_ssl>.

If you do not provide an API token, you will only be able to use Postmark's
spam score API (you will not be able to send emails).

Note that in order to use SSL, C<HTTP::Tiny> requires certain dependencies
to be installed. See L<HTTP::Tiny/"SSL SUPPORT"> for more information.

=cut

sub new {
	my ($class, $token, $use_ssl) = @_;

	carp "You have not provided a Postmark API token, you will not be able to send emails."
		unless $token;

	$use_ssl ||= 0;
	$use_ssl = 1 if $use_ssl;

	bless { token => $token, use_ssl => $use_ssl }, $class;
}

=head2 send( %params )

Receives a hash representing the email message that should be sent and
attempts to send it through the Postmark service. If the message was
successfully sent, a hash reference of Postmark's response is returned
(refer to L<the relevant Postmark documentation|http://developer.postmarkapp.com/developer-build.html#success-response>);
otherwise, this method will croak with an approriate error message (see
L</"DIAGNOSTICS"> for a full list).

The following keys are required when using this method:

=over

=item * from

The email address of the sender. Either pass the email address itself
in the format 'mail_address@domain.tld' or also provide a name, like
'My Name <mail_address@domain.tld>'.

=item * to

The email address(es) of the recipient(s). You can use both formats as in
'to', but here you can give multiple addresses. Use a comma to separate
them. Note, however, that Postmark limits this to 20 recipients and sending
will fail if you attempt to send to more than 20 addresses.

=item * subject

The subject of your message.

=item * body

The body of your message. This could be plain text, or HTML. If you want
to send HTML, be sure to open with '<html>' and close with '</html>'. This
module will look for these tags in order to find out whether you're sending
a text message or an HTML message.

Since version 0.3, however, you can explicitly specify the type of your
message, and also send both plain text and HTML. To do so, use the C<html>
and/or C<text> attributes. Their presence will override C<body>.

=item * html

Instead of using C<body> you can also specify the HTML content directly.

=item * text

... or the plain text part of the email.

=back

You can optionally supply the following parameters as well:

=over

=item * cc, bcc

Same rules as the 'to' parameter.

=item * tag

Can be used to label your mail messages according to different categories,
so you can analyze statistics of your mail sendings through the Postmark service.

=item * attachments

An array-ref with paths of files to attach to the email. C<WWW::Postmark> will
automatically determine the MIME types of these files and encode their contents
to base64 as Postmark requires.

=item * reply_to

Will force recipients of your email to send their replies to this mail
address when replying to your email.

=item * track_opens

Set to a true value to enable Postmark's open tracking functionality.

=back

=cut

sub send {
	my ($self, %params) = @_;

	# do we have an API token?
	croak "You have not provided a Postmark API token, you cannot send emails"
		unless $self->{token};

	# make sure there's a from address
	croak "You must provide a valid 'from' address in the format 'address\@domain.tld', or 'Your Name <address\@domain.tld>'."
		unless $params{from} && Email::Valid->address($params{from});

	# make sure there's at least on to address
	croak $self->_recipient_error('to')
		unless $params{to};

	# validate all 'to' addresses
	$self->_validate_recipients('to', $params{to});

	# make sure there's a subject
	croak "You must provide a mail subject."
		unless $params{subject};

	# make sure there's a mail body
	croak "You must provide a mail body."
		unless $params{body} or $params{html} or $params{text};

	# if cc and/or bcc are provided, validate them
	if ($params{cc}) {
		$self->_validate_recipients('cc', $params{cc});
	}
	if ($params{bcc}) {
		$self->_validate_recipients('bcc', $params{bcc});
	}

	# if reply_to is provided, validate it
	if ($params{reply_to}) {
		croak "You must provide a valid reply-to address, in the format 'address\@domain.tld', or 'Some Name <address\@domain.tld>'."
			unless Email::Valid->address($params{reply_to});
	}

	# parse the body param, unless html or text are present
	unless ($params{html} || $params{text}) {
		my $body = delete $params{body};
		if ($body =~ m/^\<html\>/i && $body =~ m!\</html\>$!i) {
			# this is an HTML message
			$params{html} = $body;
		} else {
			# this is a test message
			$params{text} = $body;
		}
	}

	# all's well, let's try an send this

	# create the message data structure
	my $msg = {
		From => $params{from},
		To => $params{to},
		Subject => $params{subject},
	};

	$msg->{HtmlBody} = $params{html} if $params{html};
	$msg->{TextBody} = $params{text} if $params{text};
	$msg->{Cc} = $params{cc} if $params{cc};
	$msg->{Bcc} = $params{bcc} if $params{bcc};
	$msg->{Tag} = $params{tag} if $params{tag};
	$msg->{ReplyTo} = $params{reply_to} if $params{reply_to};
	$msg->{TrackOpens} = 1 if $params{track_opens};

	if ($params{attachments} && ref $params{attachments} eq 'ARRAY') {
		# for every file, we need to determine its MIME type and
		# create a base64 representation of its content
		foreach (@{$params{attachments}}) {
			my ($buf, $content);

			open FILE, $_
				|| croak "Failed opening attachment $_: $!";

			while (read FILE, $buf, 60*57) {
				$content .= encode_base64($buf);
			}

			close FILE;

			push(@{$msg->{Attachments} ||= []}, {
				Name => basename($_),
				ContentType => mimetype($_),
				Content => $content
			});
		}
	}

	# create and send the request
	my $res = $ua->request(
		'POST',
		'http' . ($self->{use_ssl} ? 's' : '') . '://api.postmarkapp.com/email',
		{
			headers => {
				'Accept' => 'application/json',
				'Content-Type' => 'application/json',
				'X-Postmark-Server-Token' => $self->{token},
			},
			content => encode_json($msg),
		}
	);

	# analyze the response
	if ($res->{success}) {
		# woooooooooooooeeeeeeeeeeee
		return decode_json($res->{content});
	} else {
		if ($msg->{Attachments}) {
			print STDERR $res->{content};
		}
		croak "Failed sending message: ".$self->_analyze_response($res);
	}
}

=head2 spam_score( $raw_email, [ $options ] )

Use Postmark's SpamAssassin API to determine the spam score of an email
message. You need to provide the raw email text to this method, with all
headers intact. If C<$options> is 'long' (the default), this method
will return a hash-ref with a 'report' key, containing the full
SpamAssasin report, and a 'score' key, containing the spam score. If
C<$options> is 'short', only the spam score will be returned (directly, not
in a hash-ref).

If the API returns an error, this method will croak.

Note that the SpamAssassin API is currently HTTP only, there is no HTTPS
interface, so the C<use_ssl> option to the C<new()> method is ignored here.

For more information about this API, go to L<http://spamcheck.postmarkapp.com>.

=cut

sub spam_score {
	my ($self, $raw_email, $options) = @_;

	croak 'You must provide the raw email text to spam_score().'
		unless $raw_email;

	$options ||= 'long';

	my $res = $ua->request(
		'POST',
		'http://spamcheck.postmarkapp.com/filter',
		{
			headers => {
				'Accept' => 'application/json',
				'Content-Type' => 'application/json',
			},
			content => encode_json({
				email => $raw_email,
				options => $options,
			}),
		}
	);

	# analyze the response
	if ($res->{success}) {
		# doesn't mean we have succeeded, an error may have been returned
		my $ret = decode_json($res->{content});
		if ($ret->{success}) {
			return $options eq 'long' ? $ret : $ret->{score};
		} else {
			croak "Postmark spam score API returned error: ".$ret->{message};
		}
	} else {
		croak "Failed determining spam score: $res->{content}";
	}
}

##################################
##      INTERNAL METHODS        ##
##################################

sub _validate_recipients {
	my ($self, $field, $param) = @_;

	# split all addresses
	my @ads = split(/, ?/, $param);

	# make sure there are no more than twenty
	croak $self->_recipient_error($field)
		if scalar @ads > 20;

	# validate them
	foreach (@ads) {
		croak $self->_recipient_error($field)
			unless Email::Valid->address($_);
	}

	# all's well
	return 1;
}

sub _recipient_error {
	my ($self, $field) = @_;

	return "You must provide a valid '$field' address or addresses, in the format 'address\@domain.tld', or 'Some Name <address\@domain.tld>'. If you're sending to multiple addresses, separate them with commas. You can send up to 20 maximum addresses.";
}

sub _analyze_response {
	my ($self, $res) = @_;

	return $res->{status} == 401 ? 'Missing or incorrect API Key header.' :
		 $res->{status} == 422 ? $self->_extract_error($res->{content}) :
		 $res->{status} == 500 ? 'Postmark service error. The service might be down.' :
			"Unknown HTTP error code $res->{status}.";
}

sub _extract_error {
	my ($self, $content) = @_;

	my $msg = decode_json($content);

	my %errors = (
		10	=> 'Bad or missing API token',
		300	=> 'Invalid email request',
		400	=> 'Sender signature not found',
		401	=> 'Sender signature not confirmed',
		402	=> 'Invalid JSON',
		403	=> 'Incompatible JSON',
		405	=> 'Not allowed to send',
		406	=> 'Inactive recipient',
		409	=> 'JSON required',
		410	=> 'Too many batch messages',
		411	=> 'Forbidden attachment type'
	);

	my $code_msg = $errors{$msg->{ErrorCode}} || "Unknown Postmark error code $msg->{ErrorCode}";

	return $code_msg . ': '. $msg->{Message};
}

=head1 DIAGNOSTICS

The following exceptions are thrown by this module:

=over

=item C<< "You have not provided a Postmark API token, you cannot send emails" >>

This means you haven't provided the C<new()> subroutine your Postmark API token.
Using the Postmark API requires an API token, received when registering to their
service via their website.

=item C<< "You must provide a mail subject." >>

This error means you haven't given the C<send()> method a subject for your email
message. Messages sent with this module must have a subject.

=item C<< "You must provide a mail body." >>

This error means you haven't given the C<send()> method a body for your email
message. Messages sent with this module must have content.

=item C<< "You must provide a valid 'from' address in the format 'address\@domain.tld', or 'Your Name <address\@domain.tld>'." >>

This error means the address (or one of the addresses) you're trying to send
an email to with the C<send()> method is not a valid email address (in the sense
that it I<cannot> be an email address, not in the sense that the email address does not
exist (For example, "asdf" is not a valid email address).

=item C<< "You must provide a valid reply-to address, in the format 'address\@domain.tld', or 'Some Name <address\@domain.tld>'." >>

This error, when providing the C<reply-to> parameter to the C<send()> method,
means the C<reply-to> value is not a valid email address.

=item C<< "You must provide a valid '%s' address or addresses, in the format 'address\@domain.tld', or 'Some Name <address\@domain.tld>'. If you're sending to multiple addresses, separate them with commas. You can send up to 20 maximum addresses." >>

Like the above two error messages, but for other email fields such as C<cc> and C<bcc>.

=item C<< "Failed sending message: %s" >>

This error is thrown when sending an email fails. The error message should
include the actual reason for the failure. Usually, the error is returned by
the Postmark API. For a list of errors returned by Postmark and their meaning,
take a look at L<http://developer.postmarkapp.com/developer-build.html>.

=item C<< "Unknown Postmark error code %s" >>

This means Postmark returned an error code that this module does not
recognize. The error message should include the error code. If you find
that error code in L<http://developer.postmarkapp.com/developer-build.html>,
it probably means this is a new error code this module does not know about yet,
so please open an appropriate bug report.

=item C<< "Unknown HTTP error code %s." >>

This means the Postmark API returned an unexpected HTTP status code. The error
message should include the status code returned.

=item C<< "Failed opening attachment %s: %s" >>

This error means C<WWW::Postmark> was unable to open a file attachment you have
supplied for reading. This could be due to permission problem or the file not
existing. The full error message should detail the exact cause.

=item C<< "You must provide the raw email text to spam_score()." >>

This error means you haven't passed the C<spam_score()> method the
requried raw email text.

=item C<< "Postmark spam score API returned error: %s" >>

This error means the spam score API failed parsing your raw email
text. The error message should include the actual reason for the failure.
This would be an I<expected> API error. I<Unexpected> API errors will
be thrown with the next error message.

=item C<< "Failed determining spam score: %s" >>

This error means the spam score API returned an HTTP error. The error
message should include the actual error message returned.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
C<WWW::Postmark> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<WWW::Postmark> B<depends> on the following CPAN modules:

=over

=item * L<Carp>

=item * L<Email::Valid>

=item * L<HTTP::Tiny>

=item * L<JSON::MaybeXS>

=item * L<File::MimeInfo>

=item * L<MIME::Base64>

=back

C<WWW::Postmark> recommends L<Cpanel::JSON::XS> for parsing JSON (the Postmark API
is JSON based). If installed, L<JSON::MaybeXS> will automatically load L<Cpanel::JSON::XS>
or L<JSON::XS>. For SSL support, L<IO::Socket::SSL> and L<Net::SSLeay> will also be
needed.

=head1 INCOMPATIBILITIES WITH OTHER MODULES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-WWW-Postmark@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Postmark>.

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

With help from: Casimir Loeber.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ido Perlmuter

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
__END__
