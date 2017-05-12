# NAME

WWW::Postmark - API for the Postmark mail service for web applications.

# SYNOPSIS

        use WWW::Postmark;

        my $api = WWW::Postmark->new('api_token');
        
        # or, if you want to use SSL
        my $api = WWW::Postmark->new('api_token', 1);

        # send an email
        $api->send(from => 'me@domain.tld', to => 'you@domain.tld, them@domain.tld',
        subject => 'an email message', body => "hi guys, what's up?");

# DESCRIPTION

The WWW::Postmark module provides a simple API for the Postmark web service,
that provides email sending facilities for web applications. Postmark is
located at [http://postmarkapp.com](http://postmarkapp.com). It is a paid service that charges
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
The token is 'POSTMARK\_API\_TEST', and you can use it for testing purposes
(the tests in this distribution use this token).

Besides sending emails, this module also provides support for Postmark's
spam score API, which allows you to get a SpamAssassin report for an email
message. See documentation for the `spam_score()` method for more info.

# METHODS

## new( \[ $api\_token, $use\_ssl\] )

Creates a new instance of this class, with a Postmark API token that you've
received from the Postmark app. By default, requests are made through HTTP;
if you want to send them with SSL encryption, pass a true value for
`$use_ssl`.

If you do not provide an API token, you will only be able to use Postmark's
spam score API (you will not be able to send emails).

Note that in order to use SSL, `HTTP::Tiny` requires certain dependencies
to be installed. See ["SSL SUPPORT" in HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny#SSL-SUPPORT) for more information.

## send( %params )

Receives a hash representing the email message that should be sent and
attempts to send it through the Postmark service. If the message was
successfully sent, a hash reference of Postmark's response is returned
(refer to [the relevant Postmark documentation](http://developer.postmarkapp.com/developer-build.html#success-response));
otherwise, this method will croak with an approriate error message (see
["DIAGNOSTICS"](#diagnostics) for a full list).

The following keys are required when using this method:

- from

    The email address of the sender. Either pass the email address itself
    in the format 'mail\_address@domain.tld' or also provide a name, like
    'My Name <mail\_address@domain.tld>'.

- to

    The email address(es) of the recipient(s). You can use both formats as in
    'to', but here you can give multiple addresses. Use a comma to separate
    them. Note, however, that Postmark limits this to 20 recipients and sending
    will fail if you attempt to send to more than 20 addresses.

- subject

    The subject of your message.

- body

    The body of your message. This could be plain text, or HTML. If you want
    to send HTML, be sure to open with '<html>' and close with '</html>'. This
    module will look for these tags in order to find out whether you're sending
    a text message or an HTML message.

    Since version 0.3, however, you can explicitly specify the type of your
    message, and also send both plain text and HTML. To do so, use the `html`
    and/or `text` attributes. Their presence will override `body`.

- html

    Instead of using `body` you can also specify the HTML content directly.

- text

    ... or the plain text part of the email.

You can optionally supply the following parameters as well:

- cc, bcc

    Same rules as the 'to' parameter.

- tag

    Can be used to label your mail messages according to different categories,
    so you can analyze statistics of your mail sendings through the Postmark service.

- attachments

    An array-ref with paths of files to attach to the email. `WWW::Postmark` will
    automatically determine the MIME types of these files and encode their contents
    to base64 as Postmark requires.

- reply\_to

    Will force recipients of your email to send their replies to this mail
    address when replying to your email.

- track\_opens

    Set to a true value to enable Postmark's open tracking functionality.

## spam\_score( $raw\_email, \[ $options \] )

Use Postmark's SpamAssassin API to determine the spam score of an email
message. You need to provide the raw email text to this method, with all
headers intact. If `$options` is 'long' (the default), this method
will return a hash-ref with a 'report' key, containing the full
SpamAssasin report, and a 'score' key, containing the spam score. If
`$options` is 'short', only the spam score will be returned (directly, not
in a hash-ref).

If the API returns an error, this method will croak.

Note that the SpamAssassin API is currently HTTP only, there is no HTTPS
interface, so the `use_ssl` option to the `new()` method is ignored here.

For more information about this API, go to [http://spamcheck.postmarkapp.com](http://spamcheck.postmarkapp.com).

# DIAGNOSTICS

The following exceptions are thrown by this module:

- `"You have not provided a Postmark API token, you cannot send emails"`

    This means you haven't provided the `new()` subroutine your Postmark API token.
    Using the Postmark API requires an API token, received when registering to their
    service via their website.

- `"You must provide a mail subject."`

    This error means you haven't given the `send()` method a subject for your email
    message. Messages sent with this module must have a subject.

- `"You must provide a mail body."`

    This error means you haven't given the `send()` method a body for your email
    message. Messages sent with this module must have content.

- `"You must provide a valid 'from' address in the format 'address\@domain.tld', or 'Your Name <address\@domain.tld>'."`

    This error means the address (or one of the addresses) you're trying to send
    an email to with the `send()` method is not a valid email address (in the sense
    that it _cannot_ be an email address, not in the sense that the email address does not
    exist (For example, "asdf" is not a valid email address).

- `"You must provide a valid reply-to address, in the format 'address\@domain.tld', or 'Some Name <address\@domain.tld>'."`

    This error, when providing the `reply-to` parameter to the `send()` method,
    means the `reply-to` value is not a valid email address.

- `"You must provide a valid '%s' address or addresses, in the format 'address\@domain.tld', or 'Some Name <address\@domain.tld>'. If you're sending to multiple addresses, separate them with commas. You can send up to 20 maximum addresses."`

    Like the above two error messages, but for other email fields such as `cc` and `bcc`.

- `"Failed sending message: %s"`

    This error is thrown when sending an email fails. The error message should
    include the actual reason for the failure. Usually, the error is returned by
    the Postmark API. For a list of errors returned by Postmark and their meaning,
    take a look at [http://developer.postmarkapp.com/developer-build.html](http://developer.postmarkapp.com/developer-build.html).

- `"Unknown Postmark error code %s"`

    This means Postmark returned an error code that this module does not
    recognize. The error message should include the error code. If you find
    that error code in [http://developer.postmarkapp.com/developer-build.html](http://developer.postmarkapp.com/developer-build.html),
    it probably means this is a new error code this module does not know about yet,
    so please open an appropriate bug report.

- `"Unknown HTTP error code %s."`

    This means the Postmark API returned an unexpected HTTP status code. The error
    message should include the status code returned.

- `"Failed opening attachment %s: %s"`

    This error means `WWW::Postmark` was unable to open a file attachment you have
    supplied for reading. This could be due to permission problem or the file not
    existing. The full error message should detail the exact cause.

- `"You must provide the raw email text to spam_score()."`

    This error means you haven't passed the `spam_score()` method the
    requried raw email text.

- `"Postmark spam score API returned error: %s"`

    This error means the spam score API failed parsing your raw email
    text. The error message should include the actual reason for the failure.
    This would be an _expected_ API error. _Unexpected_ API errors will
    be thrown with the next error message.

- `"Failed determining spam score: %s"`

    This error means the spam score API returned an HTTP error. The error
    message should include the actual error message returned.

# CONFIGURATION AND ENVIRONMENT

`WWW::Postmark` requires no configuration files or environment variables.

# DEPENDENCIES

`WWW::Postmark` **depends** on the following CPAN modules:

- [Carp](https://metacpan.org/pod/Carp)
- [Email::Valid](https://metacpan.org/pod/Email::Valid)
- [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny)
- [JSON::MaybeXS](https://metacpan.org/pod/JSON::MaybeXS)
- [File::MimeInfo](https://metacpan.org/pod/File::MimeInfo)
- [MIME::Base64](https://metacpan.org/pod/MIME::Base64)

`WWW::Postmark` recommends [Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel::JSON::XS) for parsing JSON (the Postmark API
is JSON based). If installed, [JSON::MaybeXS](https://metacpan.org/pod/JSON::MaybeXS) will automatically load [Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel::JSON::XS)
or [JSON::XS](https://metacpan.org/pod/JSON::XS). For SSL support, [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) and [Net::SSLeay](https://metacpan.org/pod/Net::SSLeay) will also be
needed.

# INCOMPATIBILITIES WITH OTHER MODULES

None reported.

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
`bug-WWW-Postmark@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Postmark](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Postmark).

# AUTHOR

Ido Perlmuter <ido@ido50.net>

With help from: Casimir Loeber.

# LICENSE AND COPYRIGHT

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
