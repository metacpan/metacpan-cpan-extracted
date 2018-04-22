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
    return unless $wm;

    if ( $wm->is_verified ) {
        my $author = $wm->author;
        my $name;
        if ( $author ) {
            $name = $author->name;
        }
        else {
            $name = 'somebody';
        }

        my $source = $wm->original_source;
        my $target = $wm->target;

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

    # Manually buidling a webmention:

    my $wm = Web::Mention->new(
       source => $url_of_the_thing_that_got_mentioned,
       target => $url_of_the_thing_that_did_the_mentioning
    );

    # Sending a webmention:
    # ...watch this space.

# DESCRIPTION

This class implements the Webmention protocol, as defined by the W3C and
the IndieWeb community. (See: [https://indieweb.org/Webmention](https://indieweb.org/Webmention))

An object of this class represents a single webmention, with target and
source URLs. It can verify itself, determining whether or not the
document found at the source URL does indeed mention the target URL. It
can also use the Indieweb authorship algorithm to identify and describe
the author of source document, if possible.

# METHODS

## Class Methods

### new

    $wm = Web::Mention->new( source => $source_url, target => $target_url );

Basic constructor. The **source** and **target** URLs are both required
arguments. Either one can either be a [URI](https://metacpan.org/pod/URI) object, or a valid URL
string.

Per the Webmention protocol, the **source** URL represents the location
of the document that made the mention described here, and **target**
describes the location of the document that got mentioned.

### new\_from\_request

    $wm = Web::Mention->new_from_request( $request_object );

Convenience constructor that looks into the given web-request object for
**source** and **target** parameters, and attempts to build a new
Web::Mention object out of them.

The object must provide a `param( $param_name )` method that returns the
value of the named HTTP parameter. So it could be a [Catalyst::Request](https://metacpan.org/pod/Catalyst::Request)
object or a [Mojo::Message::Request](https://metacpan.org/pod/Mojo::Message::Request) object, for example.

Throws an exception if the given argument doesn't meet this requirement,
or if it does but does not define both required HTTP parameters.

## Object Methods

### source

    $source_url = $wm->source;

Returns the webmention's source URL, as a [URI](https://metacpan.org/pod/URI) object.

### target

    $target_url = $wm->target;

Returns the webmention's target URL, as a [URI](https://metacpan.org/pod/URI) object.

### is\_verified

    $bool = $wm->is_verified;

Returns 1 if the webmention's source document actually does seem to
mention the target URL. Otherwise returns 0.

The first time this is called on a given webmention object, it will try
to fetch the source document at its designated URL. If it cannot fetch
the document on this first attempt, this method returns 0.

### type

    $type = $wm->type;

The type of webmention this is. One of:

- mention _(default)_
- reply
- like
- repost
- quotation

### author

    $author = $wm->author;

A Web::Mention::Author object representing the author of this
webmention's source document, if we're able to determine it. If not,
this returns undef.

### source\_html

    $html = $wm->source_html;

The HTML of the document fetched from the source URL. If nothing got
fetched successfully, returns undef.

### source\_mf2\_document

    $mf2_doc = $wm->source_mf2_document;

The [Web::Microformats2::Document](https://metacpan.org/pod/Web::Microformats2::Document) object that resulted from parsing the
source document for Microformats2 metadata. If no such result, returns
undef.

### content

    $content = $wm->content;

The content of this webmention, if its source document exists and
defines its content using Microformats2. If not, this returns undef.

### original\_source

    $original_url = $wm->original_source;

If the document fetched from the source URL seems to point at yet
another URL as its original source, then this returns that URL. If not,
this has the same return value as `source()`.

(It makes this determination based on the possible presence a `u-url`
property in an `h-entry` found within the source document.)

# NOTES AND BUGS

Implementation of the content-fetching method is incomplete.

This software is **alpha**; its author is still determining how it wants
to work, and its interface might change dramatically.

# SUPPORT

To file issues or submit pull requests, please see [this module's
repository on GitHub](https://github.com/jmacdotorg/webmention-perl).

The author also welcomes any direct questions about this module via email.

# AUTHOR

Jason McIntosh (jmac@jmac.org)

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jason McIntosh.

This is free software, licensed under:

    The MIT (X11) License
