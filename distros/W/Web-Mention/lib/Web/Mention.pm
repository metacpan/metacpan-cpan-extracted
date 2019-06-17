package Web::Mention;

use Moose;
use MooseX::ClassAttribute;
use MooseX::Types::URI qw(Uri);
use LWP;
use HTTP::Link;
use DateTime;
use String::Truncate qw(elide);
use Try::Tiny;
use Types::Standard qw(Enum);
use MooseX::Enumeration;
use Scalar::Util;
use Carp qw(carp croak);
use Mojo::DOM58;
use URI::Escape;
use Encode qw(decode_utf8);
use Readonly;

use Web::Microformats2::Parser;
use Web::Mention::Author;

our $VERSION = '0.702';

Readonly my @VALID_RSVP_TYPES => qw(yes no maybe interested);

has 'source' => (
    isa => Uri,
    is => 'ro',
    required => 1,
    coerce => 1,
);

has 'original_source' => (
    isa => Uri,
    is => 'ro',
    lazy_build => 1,
    coerce => 1,
);

has 'source_html' => (
    isa => 'Maybe[Str]',
    is => 'rw',
);

has 'source_mf2_document' => (
    isa => 'Maybe[Web::Microformats2::Document]',
    is => 'rw',
    lazy_build => 1,
    clearer => '_clear_mf2',
);

has 'target' => (
    isa => Uri,
    is => 'ro',
    required => 1,
    coerce => 1,
);

has 'endpoint' => (
    isa => 'Maybe[URI]',
    is => 'ro',
    lazy_build => 1,
);

has 'is_tested' => (
    isa => 'Bool',
    is => 'rw',
    default => 0,
);

has 'is_verified' => (
    isa => 'Bool',
    is => 'ro',
    lazy_build => 1,
);

has 'time_verified' => (
    isa => 'DateTime',
    is => 'rw',
);

has 'time_received' => (
    isa => 'DateTime',
    is => 'ro',
    default => sub{ DateTime->now },
);

has 'rsvp_type' => (
    isa => 'Maybe[Str]',
    is => 'ro',
    lazy_build => 1,
);

has 'author' => (
    isa => 'Maybe[Web::Mention::Author]',
    is => 'ro',
    lazy_build => 1,
    clearer => '_clear_author',
);

has 'type' => (
    isa => Enum[qw(rsvp reply like repost quotation mention)],
    traits => ['Enumeration'],
    handles => [qw(is_rsvp is_reply is_like is_repost is_quotation is_mention)],
    is => 'ro',
    lazy_build => 1,
    clearer => '_clear_type',
);

has 'content' => (
    isa => 'Maybe[Str]',
    is => 'ro',
    lazy_build => 1,
    clearer => '_clear_content',
);

has 'title' => (
    isa => 'Maybe[Str]',
    is => 'ro',
    lazy_build => 1,
    clearer => '_clear_title',
);

has 'response' => (
    isa => 'HTTP::Response',
    is => 'rw',
);

class_has 'ua' => (
    isa => 'LWP::UserAgent',
    is => 'rw',
    default => sub { LWP::UserAgent->new },
);

class_has 'max_content_length' => (
    isa => 'Num',
    is => 'rw',
    default => 200,
);

class_has 'content_truncation_marker' => (
    isa => 'Str',
    is => 'rw',
    default => '...',
);

sub _build_is_verified {
    my $self = shift;

    return $self->verify;
}

sub BUILD {
    my $self = shift;

    my $source = $self->source->clone;
    my $target = $self->target->clone;

    foreach ( $source, $target ) {
	$_->fragment( undef );
    }

    if ( $source->eq( $target ) ) {
	die "Inavlid webmention; source and target have the same URL "
	    . "($source)\n";
    }
}

sub new_from_request {
    my $class = shift;

    my ( $request ) = @_;

    unless ( blessed($request) && $request->can('param') ) {
        croak 'The argument to new_from_request must be an object that '
              . "supports a param() method. (Got: $request)\n";
    }

    my @complaints;
    my %new_args;
    foreach ( qw(source target) ) {
        if ( my $value = $request->param( $_ ) ) {
            $new_args{ $_ } = $value;
        }

        unless ( defined $new_args{ $_ } ) {
            push @complaints, "No param value set for $_.";
        }
    }

    if ( @complaints ) {
        croak join q{ }, @complaints;
    }

    return $class->new( %new_args );
}

sub new_from_html {
    my $class = shift;

    my %args = @_;
    my $source = $args{ source };
    my $html = $args{ html };

    unless ($source) {
        croak "You must define a source URL when calling new_from_html.";
    }

    my @webmentions;

    my $dom = Mojo::DOM58->new( $html );
    my $nodes_ref = $dom->find( 'a[href]' );
    for my $node ( @$nodes_ref ) {
        push @webmentions,
            $class->new( source => $source, target => $node->attr( 'href' ) );
    }

    return @webmentions;
}


sub verify {
    my $self = shift;

    $self->is_tested(1);
    my $response = $self->ua->get( $self->source );

    # Search for both plain and escaped ("percent-encoded") versions of the
    # target URL in the source doc. We search for the latter to account for
    # sites like Tumblr, who treat outgoing hyperlinks as weird internally-
    # pointing links that pass external URLs as query-string parameters.
    my $target = "$self->target";
    if ( ($response->content =~ $self->target)
         || ($response->content =~ uri_escape( $self->target ) )
    ) {
        $self->time_verified( DateTime->now );
        $self->source_html( $response->decoded_content );
        $self->_clear_mf2;
        $self->_clear_content;
        $self->_clear_title;
        $self->_clear_author;
        $self->_clear_type;
        return 1;
    }
    else {
        return 0;
    }
}

sub send {
    my $self = shift;

    my $endpoint = $self->endpoint;
    my $source = $self->source;
    my $target = $self->target;

    unless ( $endpoint ) {
        return 0;
    }

    # Step three: send the webmention to the target!
    my $request = HTTP::Request->new( POST => $endpoint );
    $request->content_type('application/x-www-form-urlencoded');
    $request->content("source=$source&target=$target");

    my $response = $self->ua->request($request);
    $self->response( $response );

    return $response->is_success;
}

sub _build_source_mf2_document {
    my $self = shift;

    return unless $self->is_verified;
    my $doc;
    try {
        my $parser = Web::Microformats2::Parser->new;
        $doc = $parser->parse(
	    $self->source_html,
	    url_context => $self->source,
	);
    }
    catch {
        die "Error parsing source HTML: $_";
    };
    return $doc;
}

sub _build_author {
    my $self = shift;

    if ( $self->source_mf2_document ) {
        return Web::Mention::Author->new_from_mf2_document(
            $self->source_mf2_document
        );
    }
    else {
        return;
    }
}

sub _build_type {
    my $self = shift;

    unless ( $self->source_mf2_document ) {
        return 'mention';
    }

    my $item = $self->source_mf2_document->get_first( 'h-entry' );
    return 'mention' unless $item;

    # This order comes from the W3C Post Type Detection algorithm:
    # https://www.w3.org/TR/post-type-discovery/#response-algorithm
    # ...except adding 'quotation' as a final allowed type, before
    # defaulting to 'mention'.

    if ( $self->rsvp_type
         && $self->_check_url_property( $item, 'in-reply-to' ) ) {
        return 'rsvp';
    }
    elsif ( $self->_check_url_property( $item, 'repost-of' )) {
        return 'repost';
    }
    elsif ( $self->_check_url_property( $item, 'like-of' ) ) {
        return 'like';
    }
    elsif ( $self->_check_url_property( $item, 'in-reply-to' ) ) {
        return 'reply';
    }
    elsif ( $self->_check_url_property( $item, 'quotation-of' )) {
        return 'quotation';
    }
    else {
        return 'mention';
    }
}

sub _build_content {
    my $self = shift;

    # If the source page has MF2 data *and* an h-entry,
    # then we apply the algorithm outlined at:
    # https://indieweb.org/comments#How_to_display
    #
    # Otherwise, we can't extract any semantic information about it,
    # so we'll just offer the page's title, if there is one.

    my $item;
    if ( $self->source_mf2_document ) {
        $item = $self->source_mf2_document->get_first( 'h-entry' );
    }

    unless ( $item ) {
        return $self->_title_element_content;
    }

    my $raw_content;
    if ( $item->get_property( 'content' ) ) {
        $raw_content = $item->get_property( 'content' )->{ value };
    }
    if ( defined $raw_content ) {
        if ( length $raw_content <= $self->max_content_length ) {
            return $raw_content;
        }
    }

    if ( my $summary = $item->get_property( 'summary' ) ) {
        return $self->_truncate_content( $summary );
    }

    if ( defined $raw_content ) {
        return $self->_truncate_content( $raw_content );
    }

    if ( my $name = $item->get_property( 'name' ) ) {
        return $self->_truncate_content( $name );
    }

    return $self->_truncate_content( $item->value );
}

sub _build_rsvp_type {
    my $self = shift;

    my $rsvp_type;
    if ( my $item = $self->source_mf2_document->get_first( 'h-entry' ) ) {
        if ( my $rsvp_property = $item->get_property( 'rsvp' ) ) {
            if ( grep { $_ eq lc $rsvp_property } @VALID_RSVP_TYPES ) {
                $rsvp_type = $rsvp_property;
            }
        }
    }

    return $rsvp_type;
}

sub _check_url_property {
    my $self = shift;
    my ( $item, $property ) = @_;

    my $urls_ref = $item->get_properties( $property );
    my $found = 0;

    for my $url_prop ( @$urls_ref ) {
        my $url;
        if ( blessed($url_prop) && $url_prop->isa('Web::Microformats2::Item') ) {
            $url = $url_prop->value;
        }
        else {
            $url = $url_prop;
        }

        if ( $url eq $self->target ) {
            $found = 1;
            last;
        }
    }

    return $found;
}

sub _truncate_content {
    my $self = shift;
    my ( $content ) = @_;
    unless ( defined $content ) {
        $content = q{};
    }

    return elide(
        $content,
        $self->max_content_length,
        {
            at_space => 1,
            marker => $self->content_truncation_marker,
        },
    );
}

sub _build_original_source {
    my $self = shift;

    if ( $self->source_mf2_document ) {
        if ( my $item = $self->source_mf2_document->get_first( 'h-entry' ) ) {
            if ( my $url = $item->get_property( 'url' ) ) {
                return $url;
            }
        }
    }

    return $self->source;
}

sub _build_endpoint {
    my $self = shift;

    my $endpoint;
    my $source = $self->source;
    my $target = $self->target;

    # Is it in the Link HTTP header?
    my $response = $self->ua->get( $target );
    if ( $response->header( 'Link' ) ) {
        my @header_links = HTTP::Link->parse( $response->header( 'Link' ) . '' );
        foreach (@header_links ) {
            if ($_->{relation} eq 'webmention') {
                $endpoint = $_->{iri};
            }
        }
    }

    # Is it in the HTML?
    unless ( $endpoint ) {
        if ( $response->header( 'Content-type' ) =~ m{^text/html\b} ) {
            my $dom = Mojo::DOM58->new( $response->decoded_content );
            my $nodes_ref = $dom->find(
                'link[rel~="webmention"], a[rel~="webmention"]'
            );
            for my $node (@$nodes_ref) {
                $endpoint = $node->attr( 'href' );
                last if defined $endpoint;
            }
        }
    }

    return undef unless defined $endpoint;

    $endpoint = URI->new_abs( $endpoint, $response->base );

    my $host = $endpoint->host;
    if (
        ( lc($host) eq 'localhost' ) || ( $host =~ /^127\.\d+\.\d+\.\d+$/ )
    ) {
        carp "Warning: $source declares an apparent loopback address "
              . "($endpoint) as a webmention endpoint. Ignoring.";
        return undef;
    }
    else {
        return $endpoint;
    }
}

sub _build_title {
    my $self = shift;

    # If the source doc has an h-entry with a p-name, return that, truncated.
    if ( $self->source_mf2_document ) {
        my $entry = $self->source_mf2_document->get_first( 'h-entry' );
        my $name;
        if ( $entry ) {
            $name = $entry->get_property( 'name' );
        }
        if ( $entry && $name ) {
            return $self->_truncate_content( $name );
        }
    }

    # Otherwise, try to return the HTML title element's content.
    return $self->_title_element_content;

}

sub _title_element_content {
    my $self = shift;

    my $title = Mojo::DOM58->new( $self->source_html )->at('title');
    if ($title) {
        return $title->text;
    }
    else {
        return undef;
    }
}

# Called by the JSON module during JSON encoding.
# Contrary to the (required) name, returns an unblessed reference, not JSON.
# See https://metacpan.org/pod/JSON#OBJECT-SERIALISATION
sub TO_JSON {
    my $self = shift;

    my $return_ref = {
        source => $self->source->as_string,
        target => $self->target->as_string,
        time_received => $self->time_received->epoch,
    };

    if ( $self->is_tested ) {
    	$return_ref->{ is_tested } = $self->is_tested;
    	$return_ref->{ is_verified } = $self->is_verified;
	    $return_ref->{ type } = $self->type;
    	$return_ref->{ time_verified } = $self->time_verified->epoch;
    	$return_ref->{ content } = $self->content;
    	$return_ref->{ source_html } = $self->source_html;
	    if ( $self->source_mf2_document ) {
    	    $return_ref->{ mf2_document_json } =
	    	decode_utf8($self->source_mf2_document->as_json);
    	}
    	else {
	        $return_ref->{ mf2_document_json } = undef;
    	}
    }

    return $return_ref;
}

# Class method to construct a Webmention object from an unblessed reference,
# as created from the TO_JSON method. All-caps-named for the sake of parity.
sub FROM_JSON {
    my $class = shift;
    my ( $data_ref ) = @_;

    foreach ( qw( time_received time_verified ) ) {
    	if ( defined $data_ref->{ $_ } ) {
    	    $data_ref->{ $_ } =
    	        DateTime->from_epoch( epoch => $data_ref->{ $_ } );
    	}
    }

    my $webmention = $class->new( $data_ref );

    if ( my $mf2_json = $data_ref->{ mf2_document_json } ) {
        my $doc = Web::Microformats2::Document->new_from_json( $mf2_json );
        $webmention->source_mf2_document( $doc );
    }

    return $webmention;
}

1;

=pod

=head1 NAME

Web::Mention - Implementation of the IndieWeb Webmention protocol

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This class implements the Webmention protocol, as defined by the W3C and
the IndieWeb community. (See L<This article by Chris
Aldrich|https://alistapart.com/article/webmentions-enabling-better-
communication-on-the-internet> for an excellent high-level summary of
Webmention and its applications.)

An object of this class represents a single webmention, with target and
source URLs. It can verify itself, determining whether or not the
document found at the source URL does indeed mention the target URL.

It can also use IndieWeb algorithms to attempt identification of the
source document's author, and to provide a short summary of that
document's content, using Microformats2 metadata when available.

=head1 METHODS

=head2 Class Methods

=head3 new

 $wm = Web::Mention->new(
    source => $source_url,
    target => $target_url,
 );

Basic constructor. The B<source> and B<target> URLs are both required
arguments. Either one can either be a L<URI> object, or a valid URL
string.

Per the Webmention protocol, the B<source> URL represents the location
of the document that made the mention described here, and B<target>
describes the location of the document that got mentioned. The two
arguments cannot refer to the same URL (disregarding the C<#fragment>
part of either, if present).

=head3 new_from_html

 @wms = Web::Mention->new_from_html(
    source => $source_url,
    html   => $html,
 );

Convenience batch-construtor that returns a (possibly empty) I<list> of
Web::Mention objects based on the single source URL (or I<URI> object)
that you pass in, as well as a string containing HTML from which we can
extract zero or more target URLs. These extracted URLs include the
C<href> attribute value of every E<lt>aE<gt> tag in the provided HTML.

Note that (as with all this class's constructors) this method won't
proceed to actually send the generated webmentions; that step remains
yours to take. (See L<"send">.)

=head3 new_from_request

 $wm = Web::Mention->new_from_request( $request_object );

Convenience constructor that looks into the given web-request object for
B<source> and B<target> parameters, and attempts to build a new
Web::Mention object out of them.

The object must provide a C<param( $param_name )> method that returns
the value of the named HTTP parameter. So it could be a
L<Catalyst::Request> object or a L<Mojo::Message::Request> object, for
example.

Throws an exception if the given argument doesn't meet this requirement,
or if it does but does not define both required HTTP parameters.

=head3 FROM_JSON

 use JSON;

 $wm = Web::Mention->FROM_JSON(
    JSON::decode_json( $serialized_webmention )
 );

Converts an unblessed hash reference resulting from an earlier
serialization (via L<JSON>) into a fully fledged Web::Mention object.
See L<"SERIALIZATION">.

The all-caps spelling comes from a perhaps-misguided attempt to pair
well with the TO_JSON method that L<JSON> requires. As such, this method
may end up deprecated in favor of a less convoluted approach in future
releases of this module.

=head3 content_truncation_marker

 Web::Mention->content_truncation_marker( $new_truncation_marker )

The text that the content method will append to text that it has
truncated, if it did truncate it. (See L<"content">.)

Defaults to C<...>.

=head3 max_content_length

 Web::Mention->max_content_length( $new_max_length )

Gets or sets the maximum length, in characters, of the content displayed
by that object method prior to truncation. (See L<"content">.)

Defaults to 200.

=head2 Object Methods

=head3 author

 $author = $wm->author;

A Web::Mention::Author object representing the author of this
webmention's source document, if we're able to determine it. If not,
this returns undef.

=head3 content

 $content = $wm->content;

Returns a string containing this object's best determination of this
webmention's I<display-ready> content, based on a number of factors.

If the source document uses Microformats2 metadata and contains an
C<h-entry> MF2 item, then returned content may come from a variety of
its constituent properties, according to L<the IndieWeb comment-display
algorithm|https://indieweb.org/comments#How_to_display>.

If not, then it returns the content of the source document's
E<lt>titleE<gt> element, with any further HTML stripped away.

In any case, the string will get truncated if it's too long. See
L<"max_content_length"> and L<"content_truncation_marker">.

=head3 endpoint

 my $uri = $wm->endpoint;

Attempts to determine the webmention endpoint URL of this webmention's
target. On success, returns a L<URI> object. On failure, returns undef.

(If the endpoint is set to localhost or a loopback IP, will return undef
and also emit a warning, because that's terribly rude behavior on the
target's part.)

=head3 is_tested

 $bool = $wm->is_tested;

Returns 1 if this object's C<verify()> method has been called at least
once, regardless of the results of that call. Returns 0 otherwise.

=head3 is_verified

 $bool = $wm->is_verified;

Returns 1 if the webmention's source document actually does seem to
mention the target URL. Otherwise returns 0.

The first time this is called on a given webmention object, it will try
to fetch the source document at its designated URL. If it cannot fetch
the document on this first attempt, this method returns 0.

=head3 original_source

 $original_url = $wm->original_source;

If the document fetched from the source URL seems to point at yet
another URL as its original source, then this returns that URL. If not,
this has the same return value as C<source()>.

(It makes this determination based on the possible presence a C<u-url>
property in an C<h-entry> found within the source document.)

=head3 response

 my $response = $wm->response;

Returns the L<HTTP::Response> object representing the response received
by this webmention instance during its most recent attempt to send
itself.

Returns undef if this webmention instance hasn't tried to send itself.

=head3 rsvp_type

 my $rsvp = $wm->rsvp_type;

If this webmention is of type C<rsvp> (see L<"type">, below), then this method returns the
type of RSVP represented. It will be one of:

=over

=item *

yes

=item *

no

=item *

maybe

=item *

interested

=back

Otherwise, returns undef.

=head3 send

 my $bool = $wm->send;

Attempts to send an HTTP-request representation of this webmention to
its target's designated webmention endpoint. This involves querying the
target URL to discover said endpoint's URL (via the C<endpoint> object
method), and then sending the actual webmention request via HTTP to that
endpoint.

If that whole process goes through successfully and the endpoint returns
a success response (meaning that it has acknowledged the webmention, and
most likely queued it for later processing), then this method returns
true. Otherwise, it returns false.

=head3 source

 $source_url = $wm->source;

Returns the webmention's source URL, as a L<URI> object.

=head3 source_html

 $html = $wm->source_html;

The HTML of the document fetched from the source URL. If nothing got
fetched successfully, returns undef.

=head3 source_mf2_document

 $mf2_doc = $wm->source_mf2_document;

The L<Web::Microformats2::Document> object that resulted from parsing
the source document for Microformats2 metadata. If no such result,
returns undef.

=head3 target

 $target_url = $wm->target;

Returns the webmention's target URL, as a L<URI> object.

=head3 time_received

 $dt = $wm->time_received;

A L<DateTime> object corresponding to this object's creation time.

=head3 time_verified

 $dt = $wm->time_verified;

If this webmention has been verified, then this will return a
L<DateTime> object corresponding to the time of verification.
(Otherwise, returns undef.)

=head3 title

 my $title = $wm->title;

Returns a string containing this object's best determination of the
I<display-ready> title of this webmention's source document,
considered separately from its content. (You can get its more complete
content via the L<"content"> method.

If the source document uses Microformats2 metadata and contains an
C<h-entry> MF2 item, I<and> that item has a C<name> property, then this
method will return the text content of that name property.

If not, then it will return the content of the source document's
E<lt>titleE<gt> element, with any further HTML stripped away.

In any case, the string will get truncated if it's too long. See
L<"max_content_length"> and L<"content_truncation_marker">.

Note that in some circumstances, the title and content methods might
return identical values. (If, for example, the source document defines
an entry with an explicit name property and no summary or content
properties.)

=head3 type

 $type = $wm->type;

The type of webmention this is. One of:

=over

=item *

mention I<(default)>

=item *

reply

=item *

like

=item *

repost

=item *

quotation

=item *

rsvp

=back

This list is based on the W3C Post Type Discovery document
(L<https://www.w3.org/TR/post-type-discovery/#response-algorithm>), and
adds a "quotation" type.

=head1 SERIALIZATION

To serialize a Web::Mention object into JSON, enable L<the JSON module's
"convert_blessed" feature|JSON/"convert_blessed">, and then use one of
that module's JSON-encoding functions on this object. This will result
in a JSON string containing all the pertinent information about the
webmention, including its verification status, any content and metadata
fetched from the target, and so on.

To unserialize a Web::Mention object serialized in this way, first
decode it into an unblessed hash reference via L<JSON>, and then pass
that as the single argument to L<the FROM_JSON class
method|"FROM_JSON">.

=head1 NOTES AND BUGS

This software is B<beta>; its interface continues to develop and remains
subject to change, but not without some effort at supporting its current
API.

This library does not, at this time, support L<the proposed "Vouch"
anti-spam extension for Webmention|https://indieweb.org/Vouch>.

=head1 SUPPORT

To file issues or submit pull requests, please see L<this module's
repository on GitHub|https://github.com/jmacdotorg/webmention-perl>.

The author also welcomes any direct questions about this module via
email.

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)

=head1 CONTRIBUTORS

=over

=item *

Mohammad S Anwar (mohammad.anwar@yahoo.com)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Jason McIntosh.

This is free software, licensed under:

  The MIT (X11) License

=head1 A PERSONAL REQUEST

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

=over

=item *

L<The American Civil Liberties Union|https://aclu.org>

=item *

L<The Democratic National Committee|https://democrats.org>

=item *

L<Earthjustice|https://earthjustice.org>

=back

