package Test::WWW::Stub;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.10";

use Carp ();
use Guard;  # guard
use LWP::Protocol::PSGI;
use Plack::Request;
use Test::More ();
use List::MoreUtils ();
use URI;

use Test::WWW::Stub::Intercepter;

my  $Intercepter = Test::WWW::Stub::Intercepter->new;
our @Requests;

my $register_g;
my $app;
sub _app { $app; }

$app = sub {
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    push @Requests, $req;

    my $uri = _normalize_uri($req->uri);

    my $stubbed_res = $Intercepter->intercept($uri, $env, $req);
    return $stubbed_res if $stubbed_res;

    my ($file, $line) = _trace_file_and_line();

    my $method = $req->method;
    warn "Unexpected external access: $method $uri at $file line $line";

    return [ 499, [], [] ];
};

sub import {
    $register_g //= LWP::Protocol::PSGI->register($app);
}

sub register {
    my ($class, $uri_or_re, $app_or_res) = @_;
    $app_or_res //= [200, [], []];

    my $handler = $Intercepter->register($uri_or_re, $app_or_res);
    defined wantarray && return guard {
        $Intercepter->unregister($uri_or_re, $handler);
    };
}

sub last_request {
    return undef unless @Requests;
    return $Requests[-1];
}

sub last_request_for {
    my ($class, $method, $url) = @_;
    my $reqs = { map { _request_signature($_) => $_ } @Requests };
    my $signature = "$method $url";
    return $reqs->{$signature};
}

sub _request_signature {
    my ($req) = @_;
    my $normalized = _normalize_uri($req->uri);
    return join ' ', $req->method, $normalized;
}

# Don't use query part of URI for handler matching.
sub _normalize_uri {
    my ($uri) = @_;
    my $cloned = $uri->clone;
    $cloned->query(undef);
    return $cloned;
}

sub requests { @Requests }

sub requested_ok {
    my ($class, $method, $url) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok(
        List::MoreUtils::any(sub {
            my $req_url = _normalize_uri($_->uri);
            $_->method eq $method && $req_url eq $url
        }, @Requests),
        "stubbed $method $url",
    ) or Test::More::diag Test::More::explain [ map { $_->method . ' ' . $_->uri } @Requests ]
}

sub clear_requests {
    @Requests = ();
}

sub _trace_file_and_line {
    my $level = $Test::Builder::Level;
    my (undef, $file, $line) = caller($level);
    # assume "Actual" caller is test file named FOOBAR.t
    while ($file && $file !~ m<\.t$>) {
        (undef, $file, $line) = caller(++$level);
    }
    ($file, $line);
}

sub unstub {
    Carp::croak 'guard is required' unless defined wantarray;
    undef $register_g;
    return guard {
        $register_g = LWP::Protocol::PSGI->register($app);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::WWW::Stub - Block and stub specified URL for LWP

=head1 SYNOPSIS

    # External http(s) access via LWP is blocked by just declaring 'use Test::WWW::Stub';
    # Note that 'require Test::WWW::Stub' or 'use Test::WWW::Stub ()' doesn't block external access.
    use Test::WWW::Stub;

    my $ua = LWP::UserAgent->new;

    my $stubbed_res = [ 200, [], ['okay'] ];

    {
        my $guard = Test::WWW::Stub->register(q<http://example.com/TEST>, $stubbed_res);

        is $ua->get('http://example.com/TEST')->content, 'okay';
    }
    isnt $ua->get('http://example.com/TEST')->content, 'okay';

    {
        # registering in void context doesn't create guard.
        Test::WWW::Stub->register(q<http://example.com/HOGE/>, $stubbed_res);

        is $ua->get('http://example.com/HOGE')->content, 'okay';
    }
    is $ua->get('http://example.com/HOGE')->content, 'okay';

    {
        # You can also use regexp for uri
        my $guard = Test::WWW::Stub->register(qr<\A\Qhttp://example.com/MATCH/\E>, $stubbed_res);

        is $ua->get('http://example.com/MATCH/hogehoge')->content, 'okay';
    }

    {
        # you can unstub and allow external access temporary
        my $unstub_guard = Test::WWW::Stub->unstub;

        # External access occurs!!
        ok $ua->get('http://example.com');
    }

    my $last_req = Test::WWW::Stub->last_request; # Plack::Request
    is $last_req->uri, 'http://example.com/MATCH/hogehoge';

    Test::WWW::Stub->requested_ok('GET', 'http://example.com/TEST'); # passes


=head1 DESCRIPTION

Test::WWW::Stub is a helper module to block external http(s) request and stub some specific requests in your test.

Because this modules uses L<LWP::Protocol::PSGI> internally, you don't have to modify target codes using L<LWP::UserAgent>.

=head1 METHODS

=over 4

=item C<register>

    my $guard = Test::WWW::Stub->register( $uri_or_re, $app_or_res );

Registers a new stub for URI C<$uri_or_re>.
If called in void context, it simply registers the stub.
Otherwise,it returns a new guard which drops the stub on destroyed.

C<$uri_or_re> is either an URI string or a compiled regular expression for URI.
C<$app_or_res> is a PSGI response array ref, or a code ref which returns a PSGI response array ref.
If C<$app_or_res> is a code ref, requests are passed to the code ref following syntax:

    my $req = Plack::Request->new($env);
    $app_or_res->($env, $req);

Once registered, C<$app_or_res> will be return from LWP::UserAgent on requesting certain URI matches C<$uri_or_re>.

=item C<requested_ok>

    Test::WWW::Stub->requested_ok($method, $uri);

Passes when C<$uri> has been requested with C<$method>, otherwise fails and dumps requests handled by Test::WWW::Stub.

This method calls C<Test::More::ok> or C<Test::More::diag> internally.

=item C<requests>

    my @requests = Test::WWW::Stub->requests;

Returns an array of L<Plack::Request> which is handled by Test::WWW::Stub.

=item C<last_request>

    my $last_req = Test::WWW::Stub->last_request;

Returns a Plack::Request object last handled by Test::WWW::Stub.

This method is same as C<[Test::WWW::Stub-E<gt>requests]-E<gt>[-1]>.

=item  C<last_request_for>

    my $last_req = Test::WWW::Stub->last_request_for($method, $uri);

Returns a C<Plack::Request> object last handled by Test::WWW::Stub and matched given HTTP method and URI.

=item C<clear_requests>

    Test::WWW::Stub->clear_requests;

Clears request history of Test::WWW::Stub.

C<[Test::WWW::Stub-E<gt>requests]> becomes empty just after this method called.

=item C<unstub>

    my $unstub_guard = Test::WWW::Stub->unstub;

Unregister stub and enables external access, and returns a guard object which re-enables stub on destroyed.

In constrast to C<register>, this method doesn't work when called in void context.

=back

=head1 LICENSE

Copyright (C) Hatena Co., Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Asato Wakisaka E<lt>asato.wakisaka@gmail.comE<gt>

Original implementation written by suzak.

=cut

