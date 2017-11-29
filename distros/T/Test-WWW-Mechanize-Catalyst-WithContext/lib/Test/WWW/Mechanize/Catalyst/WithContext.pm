package Test::WWW::Mechanize::Catalyst::WithContext;
use 5.008001;
use Moose;
use MooseX::Aliases;
use HTTP::Request;
use Carp 'croak';

require Catalyst::Test;
extends 'Test::WWW::Mechanize::Catalyst';

our $VERSION = "0.03";
$VERSION = eval $VERSION;

has ctx => (
    is      => 'ro',
    isa     => 'Maybe[Catalyst]',
    writer  => '_set_ctx',
    alias   => 'c',
    default => undef,
);

# this stores the ctx_request function as a code reference
has _get_context => (
    is      => 'ro',
    isa     => 'CodeRef',
    lazy    => 1,
    builder => '_build__get_context',
);

sub _build__get_context {
    my ($self) = @_;

    # we need $request for ctx_request
    my $request = Catalyst::Test::_build_request_export(
        undef,    # this is C::T's $self
        { class => $self->{catalyst_app}, remote => $ENV{CATALYST_SERVER} }
    );

    return Catalyst::Test::_build_ctx_request_export(
        undef,    # this is C::T's $self
        {
            class   => $self->{catalyst_app},
            request => $request,
        }
    );
}

# this is deprecated
sub get_context {
    my ( $self, $url ) = @_;

    warnings::warn( 'deprecated',
        'get_context is deprecated and will be removed in a future release' );

    croak 'url is required' unless $url;

    my $request =
        HTTP::Request->new( GET => URI->new_abs( $url, $self->base || 'http://localhost' ) );
    $self->cookie_jar->add_cookie_header($request);

    my ( $res, $c ) = $self->_get_context->($request);

    return $res, $c;
}

# This code is based on the method for Test::WWW::Mechanize::Catalyst
# and overwrites it.
sub _do_catalyst_request {
    my ( $self, $request ) = @_;

    my $uri = $request->uri;
    $uri->scheme('http')    unless defined $uri->scheme;
    $uri->host('localhost') unless defined $uri->host;

    $request = $self->prepare_request($request);
    $self->cookie_jar->add_cookie_header($request) if $self->cookie_jar;

    # Woe betide anyone who unsets CATALYST_SERVER
    return $self->_do_remote_request($request)
        if $ENV{CATALYST_SERVER};

    $self->_set_host_header($request);

    my $res = $self->_check_external_request($request);
    return $res if $res;

    my @creds = $self->get_basic_credentials( "Basic", $uri );
    $request->authorization_basic(@creds) if @creds;

    my ( $response, $c ) = $self->_get_context->($request);

    $self->_set_ctx($c);

    # LWP would normally do this, but we don't get down that far.
    $response->request($request);

    return $response;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__

=encoding utf-8

=head1 NAME

Test::WWW::Mechanize::Catalyst::WithContext - T::W::M::C can now give you $c

=begin html

<p>
<a href="https://travis-ci.org/simbabque/Test-WWW-Mechanize-Catalyst-WithContext"><img src="https://travis-ci.org/simbabque/Test-WWW-Mechanize-Catalyst-WithContext.svg?branch=master"></a>
<a href='https://coveralls.io/github/simbabque/Test-WWW-Mechanize-Catalyst-WithContext?branch=master'><img src='https://coveralls.io/repos/github/simbabque/Test-WWW-Mechanize-Catalyst-WithContext/badge.svg?branch=master' alt='Coverage Status' /></a>
<a href='https://kritika.io/users/simbabque/repos/6965918834838520/heads/master/'><img src='https://kritika.io/users/simbabque/repos/6965918834838520/heads/master/status.svg' alt='Kritika Analysis Status' /></a>
</p>

=end html

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Test::WWW::Mechanize::Catalyst::WithContext;

    my $mech = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'Catty' );

    $mech->get_ok("/");
    is $mech->ctx->stash->{foo}, "bar", "foo got set to bar";

    $mech->post_ok("login", { u => "test", p => "secret" });
    my $c = $mech->ctx; # $c is a Catalyst context
    is $c->session->{stuff}, "something", "things are in the session";

=head1 DESCRIPTION

Test::WWW::Mechanize::Catalyst::WithContext is a subclass of L<Test::WWW::Mechanize::Catalyst>
that can give you the C<$c> context object of the request you just did. This is useful for
testing if things ended up in the stash correctly, if the session got filled without reaching
into the persistence layer or to grab an instance of a model, view or controller to do tests
on them. Since the cookie jar of your C<$mech> will be used to fetch the context, things
like being logged into your app will be taken into account.

Besides that, it's just the same as L<Test::WWW::Mechanize::Catalyst>. It inherits everything
and does not overwrite any other functionality than the request making. See the docs of
L<Test::WWW::Mechanize::Catalyst> for more details.

=head1 ATTRIBUTES

=head2 ctx

=head2 c

Contains the context object for the most recent request. C<ctx> and C<c> are equivalent. Pick
the one you feel more comfortable with.

    is $mech->ctx->stash->{foo}, "bar", "foo got set to bar";
    is $mech->c->stash->{foo}, "bar", "foo got set to bar";   # equivalent
    
If you need to keep an old context around to compare things before and after a request,
assign it to a variable. The below example is contrived, but illustrates the idea.

    $mech->get_ok("/cart");
    my $first_c = $mech->ctx;

    $mech->get_ok("/cart/add/some_product");
    isnt $first_c->cart->sum_total, $mech->ctx->cart->sum_total, "total cart value changed";

If you call this before you have made any requests, it will return C<undef>. It will also
return C<undef> if there was no Catalyst context, which is the case if the request
was handled by the Plack layer directly.

=head1 METHODS

=head2 get_context($url)

This method was B<DEPRECATED!> in version 0.03 and will likely be removed in a future version.
Use L<C<< $mech->ctx >>|/ctx> instead.

Does a GET request on C<$url> and returns the L<HTTP::Response> and the request context C<$c>.

    my ( $res, $c ) = $mech->get_context('/');

This is not a C<get_ok> and does not create test output.

=head1 EXAMPLES

The following section gives a few examples where it's useful to have C<$c>.

=head2 Are we loading the right template?

If the content that comes out of your application does not really contain any distinct markers
it's very hard to check if the right stuff got rendered. Instead of trying to find something
in your HTML that helps you identify the right page with one of the content checking methods like
C<content_like>, you can just look at the template name in the stash. Of course that doesn't tell
you if it got rendered successfully, but it does tell you which template the controller decided
should be rendered.

    $mech->get_ok('/hard/to/verify/page);
    is $mech->ctx->stash->{template}, 'hard_to_verify.tt2', 'the right template got selected';

=head2 Checking what's in the session without talking to the store

If you want to look at values in the session before and after some action, you would typically
go and connect to the session store and peek around. For that, you need to know the type of the
store, how to connect to it, and your current test user's session id. This is relatively trivial
if a database (e.g. with L<Test::DBIx::Class>), but gets more complicated when you're not mocking
the store and it's something a little more esoteric. Of course you could use a different store for
your unit tests, but maybe you don't want to do that.

Enter Test::WWW::Mechanize::Catalyst::WithContext. Just grab the context before and after you
perform your action and look at the sessions.

    $mech->get('/'); # or some other url
    my $c_before = $mech->ctx;

    $mech->get('/change/session');
    my $c_after = $mech->ctx;
    isnt $c_before->session->{foo}, $c_after->session->{foo}, 'foo got changed';

Of course this could be arbitrarily complex.

=head1 BUGS

If you find any bugs please L<open an issue on github|https://github.com/simbabque/Test-WWW-Mechanize-Catalyst-WithContext/issues>.

=head1 SEE ALSO

=over

=item

L<Test::WWW::Mechanize::Catalyst>

=item

L<Test::WWW::Mechanize>

=item

L<WWW::Mechanize>

=item

L<Catalyst::Test>

=item

L<Catalyst>

=back

=head1 ATTRIBUTION

This module borrows parts of its test suite from L<Test::WWW::Mechanize::Catalyst>.

=head1 AUTHOR

simbabque <simbabque@cpan.org>

=head1 CONTRIBUTORS

=over

=item *

Robert Rothenberg

=back

=head1 LICENSE

Copyright (C) simbabque.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
