use 5.006;
package WWW::REST;
# $WWW::REST::VERSION = '0.011';
$WWW::REST::VERSION = '0.022';
use strict;
use vars '$AUTOLOAD';

use URI ();
use LWP::UserAgent ();
use HTTP::Request::Common ();
use Class::Struct ();

use constant MEMBERS => qw(_uri _ua _res dispatch);
use constant METHODS => qw(options get head post put delete trace connect);

Class::Struct::struct(map { $_ => '$' } +MEMBERS);


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


*url = \&new;


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


sub parent { $_[0]->new('../') }


sub dir {
    my @segs = $_[0]->path_segments;
    pop @segs;
    return $_[0]->new(join('/', @segs, ''));
}


1;

__END__

=pod

=head1 NAME

WWW::REST - Base class for REST resources

=head1 VERSION

version 0.022

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
    warn $url->dir->as_string;    # "http://nntp.x.perl.org/rss/"
    warn $url->parent->as_string; # "http://nntp.x.perl.org/"
    $url->delete;                 # dies with "405 Method Not Allowed"

=head1 DESCRIPTION

This module is a mixin of L<URI>, L<LWP::UserAgent>, L<HTTP::Response>
and a user-defined dispatch module.  It is currently just a proof of
concept for a resource-oriented API framework, also known as B<REST>
(Representational State Transfer).

=encoding utf-8

=head1 VERSION

version 0.022

=head1 METHODS

=head2 WWW::REST->new($string, @args)

Constructor (class method).  Takes a URL string, returns a WWW::REST
object.  The optional arguments are passed to LWP::UserAgent->new.

=head2 $url->url($string)

Constructor (instance method).  Takes a URL string, which may be
relative to the object's URL.  Returns a WWW::REST object, which
inherits the same ua (= user-agent) and dispatcher.

=head2 $url->dispatch($coderef)

Gets or sets the dispatch code reference.

=head2 $url->_uri($uri), $url->_ua($uri), $url->_res($uri)

Gets or sets the embedded URI, LWP::UserAgent and HTTP::Response
objects respectively.  Note that C<$url> can automatically delegate
method calls to embedded objects, so normally you won't need to call
those methods explicitly.

=head2 $url->get(%args), $url->post(%args), $url->head(%args), $url->put(%args), $url->delete(%args), $url->options(%args), $url->trace(%args), $url->connect(%args)

Performs the corresponding operation on the object; returns the object
itself.  If C<dispatch> is set to a code reference, the object is passed
to it instead, and returns its return value.

=head2 $url->parent()

Returns a WWW::REST object with the URL of the current object's parent
directory.

=head2 $url->dir()

Returns a WWW::REST object with the URL of the current object's current
directory.

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
unmaintained; it's kept on CPAN for historical reasons.

=head1 SEE ALSO

L<URI>, L<LWP::UserAgent>, L<HTTP::Response>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<WWW::REST>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE


Audrey Tang has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/www-rest/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc WWW::REST

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/WWW-REST>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/WWW-REST>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-REST>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/WWW-REST>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/WWW-REST>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/WWW-REST>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/W/WWW-REST>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=WWW-REST>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=WWW::REST>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-www-rest at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=WWW-REST>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-WWW-REST>

  git clone https://github.com/shlomif/perl-WWW-REST.git

=cut
