package Test::Varnish;

our $VERSION = '0.03';

use warnings;
use strict;

use Carp;
use Getopt::Long;
use HTTP::Cookies;
use HTTP::Request;
use LWP::UserAgent;
use Test::More;
use URI;

sub analyze_response {
    my ($self, $res) = @_;
    my $cached = 0;

    if ($self->verbose) {

        my $hdr_obj = $res->headers;
        my @hdr_names = $hdr_obj->header_field_names;

        # Only "X-Varnish" is the standard, but some people use
        # custom and/or debugging headers
        for my $name (@hdr_names) {
            next unless $name =~ m{^X\-Varnish};
            my $value = $res->header($name) || q{};
            diag("$name: $value");
        }

    }

    my $main_header = $res->header("X-Varnish");
    #my $status = $res->header("X-Varnish-Status");
    #my $cacheable = $res->header("X-Varnish-Cacheable");

    # "X-Varnish: 2131920313 1299858343" means cached
    # "X-Varnish: 2039442137" means not cached
    if (defined $main_header && $main_header =~ m{^ \s* \d+ \s+ \d+ \s* $}mx) {
        $cached = 1;
    }

    return $cached;
}

sub new {
    my ($class, $opt) = @_;

    $class = ref $class || $class;
    $opt ||= {};

    my $self = {
        _verbose => $opt->{verbose},
    };

    bless $self, $class;
}

sub is_cached {
    my ($self, $args, $message) = @_;

    my $is_cached = $self->_is_cached($args);
    my $url = $args->{url};

    if (! defined $is_cached) {
        $message ||= qq{Request to url '$url' failed};
        return ok(0 => $message);
    }

    $message ||= qq{Request to url '$url' should be cached by Varnish};

    return ok($is_cached, $message);
}

sub isnt_cached {
    my ($self, $args, $message) = @_;

    my $is_cached = $self->_is_cached($args);
    my $url = $args->{url};

    if (! defined $is_cached) {
        $message ||= qq{Request to url '$url' failed};
        return ok(0 => $message);
    }

    $message ||= qq{Request to $url should not be cached by Varnish};

    return ok(! $is_cached, $message);
}

sub _is_cached {
    my ($self, $args) = @_;

    if (! $args || ref $args ne 'HASH') {
        croak q{is_cached() requires a hashref};
    }

    # 'headers' is optional, 'url' is mandatory
    if (! $args->{url}) {
        croak q{is_cached() requires a 'url'};
    }

    my $res = $self->request($args);

    # Request failed, assert a test failure
    if (! $res) {
        return;
    }

    # Request successful, check if varnish has cached it
    return $self->analyze_response($res);

}

sub request {
    my ($self, $args) = @_;

    my $method = $args->{method} || q(GET);
    my $headers = $args->{headers} || {};
    my $url = $args->{url};

    if (! $url) {
        croak(q(No 'url' argument?));
    }

    #if (! exists $headers->{Host} || ! $headers->{Host}) {
    #   croak(q(No 'host' header?));
    #}

    # Init user agent object
    my $ua = $self->user_agent();

    # Avoid the '//' or varnish rules don't fire properly
    my $host = $headers->{Host};
    if (! $host) {
        my $url_obj = URI->new($url);
        if (! $url_obj) {
            croak(qq(URI failed parsing url '$url'. Can't continue without a "Host" header.));
        }
        $host = $url_obj->host();
    }

    my $req = HTTP::Request->new($method => $url);

    # We need to set HTTP/1.1 Host: header or the varnish
    # rules based on hostname won't kick in (my.cn. vs my.)
    $req->header(Host => $host);

    if ($headers) {
        while (my ($name, $value) = each %{ $headers }) {
            if ($name eq 'Cookie') {
                ($name, $value) = split '=', $value, 2;
                #diag ("Setting cookie [$name] => [$value]");
                $ua->cookie_jar->set_cookie(undef, $name, $value, '/', $host);
                #$req->header(Cookie => "$name=$value");
            }
            else {
                $req->header($name => $value);
            }
        }
    }

    my $res = $ua->request($req);

    #if ($headers && exists $headers->{Cookie}) {
    #    $ua->cookie_jar->clear_temporary_cookies();
    #}

    return $res;
}

sub _response_sets_cookies {
    my ($res) = @_;

    my $cookie_header = $res->header("Set-Cookie");
    #diag("cookie_header: " . ($cookie_header || ""));

    return defined $cookie_header && $cookie_header ne q{}
        ? 1
        : 0;
}

sub user_agent {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new( max_redirect => 0 );
    my $jar = HTTP::Cookies->new();

    $ua->agent($self->user_agent_string());
    $ua->cookie_jar($jar);

    return $ua;
}

sub user_agent_string {

    return qq{Test-Varnish/$VERSION};

}

sub verbose {
    my $self = shift;
    
    if (@_) {
        $self->{_verbose} = shift(@_) ? 1 : 0;
    }

    return $self->{_verbose};
}

1; # End of Test::Varnish

__END__

=pod

=head1 NAME

Test::Varnish - Put your Varnish server to the test!

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

Varnish is a high performance reverse proxy.

This module allows you to perform tests against a varnish server,
asserting that a given resource (URL) is cached by varnish or not.

See it as a sort of C<Test::More> extension to test Varnish.
This can be useful when you want to test that your varnish setup
and configuration works as expected.

Another use for this module would be to poll random webservers to
discover who is using Varnish.

    use Test::Varnish;

    plan tests => 2;

    my $test_client = Test::Varnish->new({
        verbose => 1
    });

    $test_client->isnt_cached(
        {
            url => 'http://my.opera.com/community/',
        },
        'My Opera frontpage is not (yet) cached by Varnish'
    );

    $test_client->is_cached(
        {
            url => 'http://www.cnn.com/',
        },
        'Is CNN.com using Varnish?'
    );

=head1 FUNCTIONS

=head2 new

Class constructor.

Allows you to create a C<Test::Varnish> object.
The allowed options are:

=over 4

=item C<verbose>

Controls the B<verbose> mode, where additional diagnostic messages
(not many, actually) are output together with the test assertions.

Set it to a true value to enable, false to disable.

=back

=head3 Example

  use Test::Varnish;

  my $tv = Test::Varnish->new();

or

  use Test::Varnish;

  my $tv = Test::Varnish->new({
      verbose => 1
  });

=head1 METHODS

=head2 analyze_response

Takes an L<HTTP::Response> object as argument. Examines the response headers
to look for the default Varnish header (C<X-Varnish>), to tell you if
the response was coming directly from the Varnish cache, or not.

In other words, this tells you if the request was a Varnish cache hit
or miss.

=head2 is_cached

C<is_cached()> is a test assertion.

Asserts that a given request to a URL with certain headers, and such,
is cached by the given Varnish instance.

Needs 2 arguments:

=over

=item * C<\%request>

Request data, as hashref. You can specify:

=over

=item C<url>

The URL where to send the request to

=item C<headers>

Additional HTTP headers, as hashref. See the example.
Most probably you will need the C<Host> header for Varnish
to direct the request to the appropriate backend. YMMV.

=back

=item * C<$message> (optional)

A message for the test assertion
(ex.: C<Request to the frontpage with cookies should not be cached>).

A default message will be provided if none is passed.

=back


=head3 Example

    use Test::Varnish;

    my $tv = Test::Varnish->new();

    $tv->is_cached(
        {
            url => 'http://your-server.your-domain.local',
            headers => {
                Host => 'www.your-domain.local',
                # ...
            }
        }
    );

or:

    use Test::Varnish;

    my $tv = Test::Varnish->new();

    $tv->is_cached(
        {
            url => 'http://192.168.1.100/super/',
            headers => {
                'Host' => 'www.your-domain.local',
                'Accept-Language' => 'it',
            }
        }, 'The super pages should always be cached, also in italian',
    );

=head2 isnt_cached

C<isnt_cached()> is a test assertion, exactly the opposite of L</is_cached>.

Asserts that a given request to a URL is B<not cached> by the queried Varnish
instance.

=head2 user_agent

Returns a suitable user agent object (currently an L<LWP::UserAgent>
instance), that can be used to interact with the varnish instance.

=head2 user_agent_string

Defines the default user agent string to be used for the requests
issued by the default user agent object returned by L</user_agent>.

You can subclass C<Test::Varnish> to define your own user agent string.
I'm not sure this is 100% reasonable. Maybe.

=head2 verbose

Used internally, tells us if we're running in verbose mode.
When verbose mode is active, the test assertions methods will output
a bunch of diagnostic messages through C<Test::More::diag()>.

B<You can activate the verbose mode by saying>:

    my $tv = Test::Varnish->new();
    $tv->verbose(1);

Or, by instantiating the C<Test::Varnish> object with
the C<verbose> option, giving it a true value:

    my $tv = Test::Varnish->new({ verbose => 1 });

=head1 AUTHOR

Cosimo Streppone, C<< <cosimo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-varnish at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Varnish>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Varnish

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Varnish>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Varnish>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Varnish>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Varnish>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Cosimo Streppone, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
