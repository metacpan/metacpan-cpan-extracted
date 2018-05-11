package Web::Mention;

use Moose;
use MooseX::ClassAttribute;
use MooseX::Types::URI qw(Uri);
use LWP;
use HTTP::Link;
use DateTime;
use Try::Tiny;
use Types::Standard qw(Enum);
use MooseX::Enumeration;
use Scalar::Util;
use Carp qw(carp croak);
use Mojo::DOM58;
use URI::Escape;
use Carp qw(croak);

use Web::Microformats2::Parser;
use Web::Mention::Author;

our $VERSION = '0.4';

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

has 'author' => (
    isa => 'Maybe[Web::Mention::Author]',
    is => 'ro',
    lazy_build => 1,
);

has 'type' => (
    isa => Enum[qw(reply like repost quotation mention)],
    traits => ['Enumeration'],
    handles => [qw(is_reply is_like is_repost is_quotation is_mention)],
    is => 'ro',
    lazy_build => 1,
);

has 'content' => (
    isa => 'Maybe[Str]',
    is => 'ro',
    lazy_build => 1,
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

    if ( $item->get_property( 'in-reply-to' ) ) {
        return 'reply';
    }
    elsif ( $item->get_property( 'like-of' ) ) {
        return 'like';
    }
    elsif ( $item->get_property( 'repost-of' )) {
        return 'repost';
    }
    elsif ( $item->get_property( 'quotation-of' )) {
        return 'quotation';
    }
    else {
        return 'mention';
    }
}

sub _build_content {
    my $self = shift;

    # XXX This is inflexible and not on-spec
    #     Current behavior: Get an explicit content property,
    #     or return the HTML document's title, if there is one.

    my $item = $self->source_mf2_document->get_first( 'h-entry' );

    if ( $item && $item->get_property( 'content' ) ) {
        return $item->get_property( 'content' )->{value};
    }
    else {
        my ( $title ) = $self->source_html =~ /<\s*\btitle\b.*?>\s*(.*?)\s*</;
        return $title;
    }
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
	$return_ref->{ is_verified } = $self->is_verified;
	$return_ref->{ type } = $self->type;
	$return_ref->{ time_verified} = $self->time_verified->epoch;
	if ( $self->source_mf2_document ) {
	    $return_ref->{ mf2_document_json } =
		$self->source_mf2_document->as_json;
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
	    $data_ref->{ $_ } = DateTime->from_epoch( epoch => $data_ref->{ $_ } );
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

 # Manually buidling and sending a webmention:

 $wm = Web::Mention->new(
    source => $url_of_the_thing_that_got_mentioned,
    target => $url_of_the_thing_that_did_the_mentioning
 );

 my $success = $wm->send;
 if ( $success ) {
     say "Webmention sent successfully!";
 }
 else {
     say "The webmention wasn't sent successfully.";
     say "Here's the response we got back..."
     say $wm->response;
 }

=head1 DESCRIPTION

This class implements the Webmention protocol, as defined by the W3C and
the IndieWeb community. (See: L<https://indieweb.org/Webmention>)

An object of this class represents a single webmention, with target and
source URLs. It can verify itself, determining whether or not the
document found at the source URL does indeed mention the target URL. It
can also use the Indieweb authorship algorithm to identify and describe
the author of source document, if possible.

=head1 METHODS

=head2 Class Methods

=head3 new

 $wm = Web::Mention->new( source => $source_url, target => $target_url );

Basic constructor. The B<source> and B<target> URLs are both required
arguments. Either one can either be a L<URI> object, or a valid URL
string.

Per the Webmention protocol, the B<source> URL represents the location
of the document that made the mention described here, and B<target>
describes the location of the document that got mentioned. The two
arguments cannot refer to the same URL (disregarding the C<#fragment>
part of either, if present).

=head3 new_from_request

 $wm = Web::Mention->new_from_request( $request_object );

Convenience constructor that looks into the given web-request object for
B<source> and B<target> parameters, and attempts to build a new
Web::Mention object out of them.

The object must provide a C<param( $param_name )> method that returns the
value of the named HTTP parameter. So it could be a L<Catalyst::Request>
object or a L<Mojo::Message::Request> object, for example.

Throws an exception if the given argument doesn't meet this requirement,
or if it does but does not define both required HTTP parameters.

=head2 Object Methods

=head3 author

 $author = $wm->author;

A Web::Mention::Author object representing the author of this
webmention's source document, if we're able to determine it. If not,
this returns undef.

=head3 content

 $content = $wm->content;

The content of this webmention, if its source document exists and
defines its content using Microformats2. If not, then it returns the content
of the source document's E<lt>titleE<gt> element, if it has one.

B<CAUTION:> Spec-compliant implementation of this method is incomplete,
and its API may change in near-future updates to this module.

=head3 endpoint

 my $uri = $wm->endpoint;

Attempts to determine the webmention endpoint URL of this webmention's
target. On success, returns a L<URI> object. On failure, returns undef.

(If the endpoint is set to localhost or a loopback IP, will return undef
and also emit a warning, because that's terribly rude behavior on the
target's part.)

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

The L<Web::Microformats2::Document> object that resulted from parsing the
source document for Microformats2 metadata. If no such result, returns
undef.

=head3 target

 $target_url = $wm->target;

Returns the webmention's target URL, as a L<URI> object.

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

=back

=head1 NOTES AND BUGS

This software is B<alpha>; its author is still determining how it wants
to work, and its interface might change dramatically.

Implementation of the content-fetching method is incomplete.

=head1 SUPPORT

To file issues or submit pull requests, please see L<this module's
repository on GitHub|https://github.com/jmacdotorg/webmention-perl>.

The author also welcomes any direct questions about this module via email.

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)

=head1 CONTRIBUTORS

=over

=item *

Mohammad S Anwar (mohammad.anwar@yahoo.com)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jason McIntosh.

This is free software, licensed under:

  The MIT (X11) License
