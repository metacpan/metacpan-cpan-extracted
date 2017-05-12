use 5.006;
package WWW::REST;
$WWW::REST::VERSION = '0.011';

use strict;
use vars '$AUTOLOAD';

use URI ();
use LWP::UserAgent ();
use HTTP::Request::Common ();
use Class::Struct ();

use constant MEMBERS => qw(_uri _ua _res dispatch);
use constant METHODS => qw(options get head post put delete trace connect);

Class::Struct::struct(map { $_ => '$' } +MEMBERS);

=head1 NAME

WWW::REST - Base class for REST resources

=head1 VERSION

This document describes version 0.011 of WWW::REST, released
May 2, 2015.

=head1 SYNOPSIS

    use XML::RSS;
    use WWW::REST;
    $url = WWW::REST->new("http://nntp.x.perl.org/rss/perl.par.rdf");
    $url->dispatch( sub {
	my $self = shift;
	die $self->status_line if $self->is_error;
	my $rss = XML::RSS->new;
	$rss->parse($self->content);
	return $rss;
    });
    $url->get( last_n => 10 )->save("par.rdf");
    $url->url("perl.perl5.porters.rdf")->get->save("p5p.rdf");
    warn $url->dir->as_string;	  # "http://nntp.x.perl.org/rss/"
    warn $url->parent->as_string; # "http://nntp.x.perl.org/"
    $url->delete;		  # dies with "405 Method Not Allowed"

=head1 DESCRIPTION

This module is a mixin of L<URI>, L<LWP::UserAgent>, L<HTTP::Response>
and an user-defined dispatch module.  It is currently just a proof of
concept for a resource-oriented API framework, also known as B<REST>
(Representational State Transfer).

=head1 METHODS

=head2 WWW::REST->new($string, @args)

Constructor (class method).  Takes an URL string, returns a WWW::REST
object.  The optional arguments are passed to LWP::UserAgent->new.

=cut

my $old_new = \&new;

*new = sub {
    my $obj = shift;
    my $class = ref($obj) || $obj;
    my $uri = shift;
    my $self = $old_new->($class);
    $self->_uri( URI->new($uri) );
    $self->_uri( $self->_uri->abs($obj->_uri) ) if ref($obj);
    $self->_ua(
	ref($obj) ? $obj->_ua : LWP::UserAgent->new( cookie_jar => {}, @_)
    );
    $self->dispatch( $obj->dispatch ) if ref($obj);
    return $self;
};

=head2 $url->url($string)

Constructor (instance method).  Takes an URL string, which may be
relative to the object's URL.  Returns a WWW::REST object, which
inherits the same ua and dispatcher.

=cut

*url = \&new;

=head2 $url->dispatch($coderef)

Gets or sets the dispatch code reference.

=head2 $url->_uri($uri), $url->_ua($uri), $url->_res($uri)

Gets or sets the embedded URI, LWP::UserAgent and HTTP::Response
objects respectively.  Note that C<$url> can automatically delegate
method calls to embedded objects, so normally you won't need to call
those method explicitly.

=cut

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/^.*:://;
    foreach my $delegate (+MEMBERS) {
	my $obj = $self->can($delegate)->($self);
	my $code = UNIVERSAL::can($obj, $AUTOLOAD) or next;
	unshift @_, $obj;
	goto &$code;
    }
    die "No such method: $AUTOLOAD";
}

sub DESTROY {}

sub _request {
    my $method = uc(+shift);
    sub {
	my $self = shift;
	$self->query_form(@_);
	my $request = _simple_req( $method, $self->as_string );
	my $res = $self->_ua->request($request);
	$self->_res($res);
	my $dispatch = $self->dispatch or return $self;
	return $dispatch->($self);
    };
}

sub _simple_req
{
    my($method, $url) = splice(@_, 0, 2);
    my $req = HTTP::Request->new($method => $url);
    my($k, $v);
    while (($k,$v) = splice(@_, 0, 2)) {
	if (lc($k) eq 'content') {
	    $req->add_content($v);
	} else {
	    $req->push_header($k, $v);
	}
    }
    $req;
}

=head2 $url->get(%args), $url->post(%args), $url->head(%args), $url->put(%args), $url->delete(%args), $url->options(%args), $url->trace(%args), $url->connect(%args)

Performs the corresponding operation to the object; returns the object
itself.  If C<dispatch> is set to a code reference, the object is passed
to it instead, and returns its return value.

=cut

BEGIN {
    foreach my $method (+METHODS) {
	no strict 'refs';
	*$method = _request($method) unless $method eq 'post';
    }
}

sub post {
    my $self = shift;
    my $request = HTTP::Request::Common::POST( $self->as_string, \@_ );
    my $res = $self->_ua->request($request);
    $self->_res($res);
    my $dispatch = $self->dispatch or return $self;
    return $dispatch->($res);
}

=head2 $url->parent()

Returns a WWW::REST object with the URL of the current object's parent
directory.

=cut

sub parent { $_[0]->new('../') }

=head2 $url->dir()

Returns a WWW::REST object with the URL of the current object's current
directory.

=cut

sub dir {
    my @segs = $_[0]->path_segments;
    pop @segs;
    return $_[0]->new(join('/', @segs, ''));
}

=head2 Methods derived from URI

    clone scheme opaque path fragment as_string canonical eq
    abs rel authority path path_query path_segments query query_form
    query_keywords userinfo host port host_port default_port

=head2 Methods derived from LWP::UserAgent

    request send_request prepare_request simple_request request
    protocols_allowed protocols_allowed protocols_forbidden
    protocols_forbidden is_protocol_supported requests_redirectable
    requests_redirectable redirect_ok credentials get_basic_credentials
    agent from timeout cookie_jar conn_cache parse_head max_size
    clone mirror proxy no_proxy

=head2 Methods derived from HTTP::Response

    code message request previous status_line base is_info
    is_success is_redirect is_error error_as_HTML current_age
    freshness_lifetime is_fresh fresh_until

=head1 NOTES

This module is considered highly experimental and essentially
unmaintained; it's kept on CPAN for historical purposes.

=cut

1;

__END__

=head1 SEE ALSO

L<URI>, L<LWP::UserAgent>, L<HTTP::Response>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<WWW::REST>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
