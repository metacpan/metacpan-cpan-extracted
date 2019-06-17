[![Build Status](https://travis-ci.org/jmacdotorg/webmention-perl.svg?branch=master)](https://travis-ci.org/jmacdotorg/webmention-perl)
# NAME

Web::Mention - Implementation of the IndieWeb Webmention protocol

# SYNOPSIS

    use Web::Mention;
    use Try::Tiny;
    use v5.10;

    # Building a webmention from an incoming web request:

    my $wm;
    try {
        # $request can be any object that provides a 'param' method, such as
        # Catalyst::Request or Mojo::Message::Request.
        $wm = Web::Mention->new_from_request ( $request )
    }
    catch {
        say "Oops, this wasn't a webmention at all: $_";
    };

    if ( $wm && $wm->is_verified ) {
        my $source = $wm->original_source;
        my $target = $wm->target;
        my $author = $wm->author;

        my $name;
        if ( $author ) {
            $name = $author->name;
        }
        else {
            $name = $wm->source->host;
        }

        if ( $wm->is_like ) {
            say "Hooray, $name likes $target!";
        }
        elsif ( $wm->is_repost ) {
            say "Gadzooks, over at $source, $name reposted $target!";
        }
        elsif ( $wm->is_reply ) {
            say "Hmm, over at $source, $name said this about $target:";
            say $wm->content;
        }
        else {
            say "I'll be darned, $name mentioned $target at $source!";
        }
    }
    else {
       say "This webmention doesn't actually mention its target URL, "
           . "so it is not verified.";
    }

    # Manually buidling and sending a webmention:

    $wm = Web::Mention->new(
       source => $url_of_the_thing_that_got_mentioned,
       target => $url_of_the_thing_that_did_the_mentioning,
    );

    my $success = $wm->send;
    if ( $success ) {
        say "Webmention sent successfully!";
    }
    else {
        say "The webmention wasn't sent successfully.";
        say "Here's the response we got back..."
        say $wm->response->as_string;
    }

    # Batch-sending a bunch of webmentions based on some published HTML

    my @wms = Web::Mention->new_from_html(
       source => $url_of_a_web_page_i_just_published,
       html   => $relevant_html_content_of_that_web_page,
    )

    for my $wm ( @wms ) {
       my $success = $wm->send;
    }

# DESCRIPTION

This class implements the Webmention protocol, as defined by the W3C and
the IndieWeb community. (See [This article by Chris
Aldrich](https://metacpan.org/pod/https:#alistapart.com-article-webmentions-enabling-better--communication-on-the-internet) for an excellent high-level summary of
Webmention and its applications.)

An object of this class represents a single webmention, with target and
source URLs. It can verify itself, determining whether or not the
document found at the source URL does indeed mention the target URL.

It can also use IndieWeb algorithms to attempt identification of the
source document's author, and to provide a short summary of that
document's content, using Microformats2 metadata when available.

# METHODS

## Class Methods

### new

    $wm = Web::Mention->new(
       source => $source_url,
       target => $target_url,
    );

Basic constructor. The **source** and **target** URLs are both required
arguments. Either one can either be a [URI](https://metacpan.org/pod/URI) object, or a valid URL
string.

Per the Webmention protocol, the **source** URL represents the location
of the document that made the mention described here, and **target**
describes the location of the document that got mentioned. The two
arguments cannot refer to the same URL (disregarding the `#fragment`
part of either, if present).

### new\_from\_html

    @wms = Web::Mention->new_from_html(
       source => $source_url,
       html   => $html,
    );

Convenience batch-construtor that returns a (possibly empty) _list_ of
Web::Mention objects based on the single source URL (or _URI_ object)
that you pass in, as well as a string containing HTML from which we can
extract zero or more target URLs. These extracted URLs include the
`href` attribute value of every &lt;a> tag in the provided HTML.

Note that (as with all this class's constructors) this method won't
proceed to actually send the generated webmentions; that step remains
yours to take. (See ["send"](#send).)

### new\_from\_request

    $wm = Web::Mention->new_from_request( $request_object );

Convenience constructor that looks into the given web-request object for
**source** and **target** parameters, and attempts to build a new
Web::Mention object out of them.

The object must provide a `param( $param_name )` method that returns
the value of the named HTTP parameter. So it could be a
[Catalyst::Request](https://metacpan.org/pod/Catalyst::Request) object or a [Mojo::Message::Request](https://metacpan.org/pod/Mojo::Message::Request) object, for
example.

Throws an exception if the given argument doesn't meet this requirement,
or if it does but does not define both required HTTP parameters.

### FROM\_JSON

    use JSON;

    $wm = Web::Mention->FROM_JSON(
       JSON::decode_json( $serialized_webmention )
    );

Converts an unblessed hash reference resulting from an earlier
serialization (via [JSON](https://metacpan.org/pod/JSON)) into a fully fledged Web::Mention object.
See ["SERIALIZATION"](#serialization).

The all-caps spelling comes from a perhaps-misguided attempt to pair
well with the TO\_JSON method that [JSON](https://metacpan.org/pod/JSON) requires. As such, this method
may end up deprecated in favor of a less convoluted approach in future
releases of this module.

### content\_truncation\_marker

    Web::Mention->content_truncation_marker( $new_truncation_marker )

The text that the content method will append to text that it has
truncated, if it did truncate it. (See ["content"](#content).)

Defaults to `...`.

### max\_content\_length

    Web::Mention->max_content_length( $new_max_length )

Gets or sets the maximum length, in characters, of the content displayed
by that object method prior to truncation. (See ["content"](#content).)

Defaults to 200.

## Object Methods

### author

    $author = $wm->author;

A Web::Mention::Author object representing the author of this
webmention's source document, if we're able to determine it. If not,
this returns undef.

### content

    $content = $wm->content;

Returns a string containing this object's best determination of this
webmention's _display-ready_ content, based on a number of factors.

If the source document uses Microformats2 metadata and contains an
`h-entry` MF2 item, then returned content may come from a variety of
its constituent properties, according to [the IndieWeb comment-display
algorithm](https://indieweb.org/comments#How_to_display).

If not, then it returns the content of the source document's
&lt;title> element, with any further HTML stripped away.

In any case, the string will get truncated if it's too long. See
["max\_content\_length"](#max_content_length) and ["content\_truncation\_marker"](#content_truncation_marker).

### endpoint

    my $uri = $wm->endpoint;

Attempts to determine the webmention endpoint URL of this webmention's
target. On success, returns a [URI](https://metacpan.org/pod/URI) object. On failure, returns undef.

(If the endpoint is set to localhost or a loopback IP, will return undef
and also emit a warning, because that's terribly rude behavior on the
target's part.)

### is\_tested

    $bool = $wm->is_tested;

Returns 1 if this object's `verify()` method has been called at least
once, regardless of the results of that call. Returns 0 otherwise.

### is\_verified

    $bool = $wm->is_verified;

Returns 1 if the webmention's source document actually does seem to
mention the target URL. Otherwise returns 0.

The first time this is called on a given webmention object, it will try
to fetch the source document at its designated URL. If it cannot fetch
the document on this first attempt, this method returns 0.

### original\_source

    $original_url = $wm->original_source;

If the document fetched from the source URL seems to point at yet
another URL as its original source, then this returns that URL. If not,
this has the same return value as `source()`.

(It makes this determination based on the possible presence a `u-url`
property in an `h-entry` found within the source document.)

### response

    my $response = $wm->response;

Returns the [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object representing the response received
by this webmention instance during its most recent attempt to send
itself.

Returns undef if this webmention instance hasn't tried to send itself.

### rsvp\_type

    my $rsvp = $wm->rsvp_type;

If this webmention is of type `rsvp` (see ["type"](#type), below), then this method returns the
type of RSVP represented. It will be one of:

- yes
- no
- maybe
- interested

Otherwise, returns undef.

### send

    my $bool = $wm->send;

Attempts to send an HTTP-request representation of this webmention to
its target's designated webmention endpoint. This involves querying the
target URL to discover said endpoint's URL (via the `endpoint` object
method), and then sending the actual webmention request via HTTP to that
endpoint.

If that whole process goes through successfully and the endpoint returns
a success response (meaning that it has acknowledged the webmention, and
most likely queued it for later processing), then this method returns
true. Otherwise, it returns false.

### source

    $source_url = $wm->source;

Returns the webmention's source URL, as a [URI](https://metacpan.org/pod/URI) object.

### source\_html

    $html = $wm->source_html;

The HTML of the document fetched from the source URL. If nothing got
fetched successfully, returns undef.

### source\_mf2\_document

    $mf2_doc = $wm->source_mf2_document;

The [Web::Microformats2::Document](https://metacpan.org/pod/Web::Microformats2::Document) object that resulted from parsing
the source document for Microformats2 metadata. If no such result,
returns undef.

### target

    $target_url = $wm->target;

Returns the webmention's target URL, as a [URI](https://metacpan.org/pod/URI) object.

### time\_received

    $dt = $wm->time_received;

A [DateTime](https://metacpan.org/pod/DateTime) object corresponding to this object's creation time.

### time\_verified

    $dt = $wm->time_verified;

If this webmention has been verified, then this will return a
[DateTime](https://metacpan.org/pod/DateTime) object corresponding to the time of verification.
(Otherwise, returns undef.)

### title

    my $title = $wm->title;

Returns a string containing this object's best determination of the
_display-ready_ title of this webmention's source document,
considered separately from its content. (You can get its more complete
content via the ["content"](#content) method.

If the source document uses Microformats2 metadata and contains an
`h-entry` MF2 item, _and_ that item has a `name` property, then this
method will return the text content of that name property.

If not, then it will return the content of the source document's
&lt;title> element, with any further HTML stripped away.

In any case, the string will get truncated if it's too long. See
["max\_content\_length"](#max_content_length) and ["content\_truncation\_marker"](#content_truncation_marker).

Note that in some circumstances, the title and content methods might
return identical values. (If, for example, the source document defines
an entry with an explicit name property and no summary or content
properties.)

### type

    $type = $wm->type;

The type of webmention this is. One of:

- mention _(default)_
- reply
- like
- repost
- quotation
- rsvp

This list is based on the W3C Post Type Discovery document
([https://www.w3.org/TR/post-type-discovery/#response-algorithm](https://www.w3.org/TR/post-type-discovery/#response-algorithm)), and
adds a "quotation" type.

# SERIALIZATION

To serialize a Web::Mention object into JSON, enable [the JSON module's
"convert\_blessed" feature](https://metacpan.org/pod/JSON#convert_blessed), and then use one of
that module's JSON-encoding functions on this object. This will result
in a JSON string containing all the pertinent information about the
webmention, including its verification status, any content and metadata
fetched from the target, and so on.

To unserialize a Web::Mention object serialized in this way, first
decode it into an unblessed hash reference via [JSON](https://metacpan.org/pod/JSON), and then pass
that as the single argument to [the FROM\_JSON class
method](#from_json).

# NOTES AND BUGS

This software is **beta**; its interface continues to develop and remains
subject to change, but not without some effort at supporting its current
API.

This library does not, at this time, support [the proposed "Vouch"
anti-spam extension for Webmention](https://indieweb.org/Vouch).

# SUPPORT

To file issues or submit pull requests, please see [this module's
repository on GitHub](https://github.com/jmacdotorg/webmention-perl).

The author also welcomes any direct questions about this module via
email.

# AUTHOR

Jason McIntosh (jmac@jmac.org)

# CONTRIBUTORS

- Mohammad S Anwar (mohammad.anwar@yahoo.com)

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Jason McIntosh.

This is free software, licensed under:

    The MIT (X11) License

# A PERSONAL REQUEST

My ability to share and maintain free, open-source software like this
depends upon my living in a society that allows me the free time and
personal liberty to create work benefiting people other than just myself
or my immediate family. I recognize that I got a head start on this due
to an accident of birth, and I strive to convert some of my unclaimed
time and attention into work that, I hope, gives back to society in some
small way.

Worryingly, I find myself today living in a country experiencing a
profound and unwelcome political upheaval, with its already flawed
democracy under grave threat from powerful authoritarian elements. These
powers wish to undermine this society, remolding it according to their
deeply cynical and strictly zero-sum philosophies, where nobody can gain
without someone else losing.

Free and open-source software has no place in such a world. As such,
these autocrats' further ascension would have a deleterious effect on my
ability to continue working for the public good.

Therefore, if you would like to financially support my work, I would ask
you to consider a donation to one of the following causes. It would mean
a lot to me if you did. (You can tell me about it if you'd like to, but
you don't have to.)

- [The American Civil Liberties Union](https://aclu.org)
- [The Democratic National Committee](https://democrats.org)
- [Earthjustice](https://earthjustice.org)
