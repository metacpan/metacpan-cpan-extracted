package Test::WWW::Hetzner::MockIO;

use Moo;
use Encode qw(decode FB_CROAK);
use JSON::MaybeXS qw(encode_json decode_json);
use URI::Escape qw(uri_unescape);
use WWW::Hetzner::HTTPResponse;

with 'WWW::Hetzner::Role::IO';

has routes => (is => 'ro', default => sub { {} });
has base_url => (is => 'ro', default => '');

sub call {
    my ($self, $req) = @_;

    my $method = $req->method;

    # Extract path and query by stripping base_url.  Routes continue to match
    # against the path alone, as they did before query-aware callbacks.
    my $path = $req->url;
    my $base = $self->base_url;
    $path =~ s{^\Q$base\E}{} if $base;
    my ($route_path, $query) = split /\?/, $path, 2;
    $path = $route_path;

    # Existing callbacks keep their decoded body.  New callbacks can inspect
    # query parameters and the unmodified transport request as well.
    my %opts = (request => $req);
    $opts{params} = _decode_form($query) if defined $query;

    if ($req->has_content && length $req->content) {
        my $content_type = $req->headers->{'Content-Type'} // '';
        if ($content_type =~ m{\Aapplication/x-www-form-urlencoded(?:\s*;|\z)}i) {
            $opts{body} = _decode_form($req->content);
        }
        else {
            # Preserve the previous JSON-decoding behavior for existing routes,
            # including callers that did not set Content-Type.
            $opts{body} = decode_json($req->content);
        }
    }

    my $key = "$method $path";
    my $routes = $self->routes;

    # Exact match
    if (exists $routes->{$key}) {
        return $self->_handle($routes->{$key}, $method, $path, %opts);
    }

    # Pattern match against $path
    for my $pattern (keys %$routes) {
        if ($path =~ /$pattern/) {
            return $self->_handle($routes->{$pattern}, $method, $path, %opts);
        }
    }

    die "No mock route for: $key";
}

sub _decode_form {
    my ($content) = @_;
    my %values;

    for my $pair (split /&/, $content, -1) {
        next unless length $pair;

        my ($key, $value) = split /=/, $pair, 2;
        $key   = _url_decode($key // '');
        $value = _url_decode($value // '');

        # Robot documents array input names as C<name[]>; callbacks receive
        # the same Perl shape supplied to post(), including a single-item array.
        my $is_array = $key =~ s/\[\]\z//;
        if ($is_array) {
            push @{ $values{$key} //= [] }, $value;
        }
        elsif (exists $values{$key}) {
            $values{$key} = [ $values{$key} ] unless ref $values{$key} eq 'ARRAY';
            push @{ $values{$key} }, $value;
        }
        else {
            $values{$key} = $value;
        }
    }

    return \%values;
}

sub _url_decode {
    my ($value) = @_;
    $value =~ tr/+/ /;
    $value = uri_unescape($value);
    return $value if utf8::is_utf8($value);
    return decode('UTF-8', $value, FB_CROAK);
}

sub _handle {
    my ($self, $handler, $method, $path, %opts) = @_;

    # If handler returns an HTTPResponse, use it directly
    if (ref $handler eq 'WWW::Hetzner::HTTPResponse') {
        return $handler;
    }

    my $data = ref $handler eq 'CODE'
        ? $handler->($method, $path, %opts)
        : $handler;

    # Allow callbacks to return HTTPResponse directly
    if (ref $data eq 'WWW::Hetzner::HTTPResponse') {
        return $data;
    }

    return WWW::Hetzner::HTTPResponse->new(
        status  => 200,
        content => ref $data ? encode_json($data) : ($data // ''),
    );
}

package Test::WWW::Hetzner::Mock;

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use Path::Tiny qw(path);
use WWW::Hetzner::Cloud;
use WWW::Hetzner::Robot;

my $FIXTURES_DIR;

BEGIN {
    # t/lib/Test/WWW/Hetzner/Mock.pm -> t/fixtures
    $FIXTURES_DIR = path(__FILE__)->parent(5)->child('fixtures');
}

# MooX::Options' _options_fix_argv translates hyphens to underscores in
# recognised option names but leaves the value it consumes from @ARGV verbatim.
# When two hyphenated flags are passed back-to-back (e.g.
# --enable-samba --enable-ssh), the second flag is consumed as the value of the
# first and pushed to @new_argv unchanged.  GLD does not auto-translate
# hyphens to underscores, so it warns "Unknown option: enable-ssh" and dies,
# options_usage calls exit(1), and the surrounding Test::Builder subtest
# never sees its done_testing -- the process exits 255 instead.
#
# Translate hyphens to underscores on the way through _options_fix_argv, but
# keep the --no- negation prefix that negatable options rely on.  The original
# implementation still runs afterwards to handle autosplit expansion and value
# consumption; because every argument is now in underscored form the consumed
# neighbour also resolves to a known option, so GLD accepts it.
BEGIN {
    require MooX::Options::Role;
    no warnings 'redefine';
    my $original = \&MooX::Options::Role::_options_fix_argv;
    *MooX::Options::Role::_options_fix_argv = sub {
        my ( $option_data, $has_to_split, $all_options ) = @_;

        # First pass: rewrite every --hyphen-name to --underscore_name
        # (preserving --no- when the option is negatable).
        my @translated;
        local @ARGV = @ARGV;
        while ( defined( my $arg = shift @ARGV ) ) {
            if ( $arg eq '--' ) {
                push @translated, $arg, @ARGV;
                last;
            }
            if ( index( $arg, '-' ) != 0 ) {
                push @translated, $arg;
                next;
            }
            my $name = $arg;
            $name =~ s/^--?//;
            my $negated = $name =~ s/^no-//;
            $name =~ s/-/_/g;
            my $entry = $all_options->{$name};
            $entry = $entry->[0] if ref $entry eq 'ARRAY';
            my $is_negatable = $entry
                && ( $option_data->{$entry}{negatable}
                    || $option_data->{$entry}{negativable} );

            my $prefix = '--';
            $prefix .= 'no-' if $negated && $is_negatable;
            push @translated, $prefix . $name;
        }

        # Second pass: let the original implementation handle autosplit
        # expansion and value consumption.  Because every argument is now
        # underscored, any value the original fix_argv grabs from @ARGV is
        # already in the form GLD expects.
        local @ARGV = @translated;
        return $original->( $option_data, $has_to_split, $all_options );
    };
}

sub import {
    my $class = shift;
    my $caller = caller;

    no strict 'refs';
    *{"${caller}::mock_cloud"} = \&mock_cloud;
    *{"${caller}::mock_robot"} = \&mock_robot;
    *{"${caller}::mock_storage"} = \&mock_storage;
    *{"${caller}::load_fixture"} = \&load_fixture;
}

sub load_fixture {
    my ($name) = @_;
    my $file = $FIXTURES_DIR->child("$name.json");
    return decode_json($file->slurp_utf8);
}

sub mock_cloud {
    my (%routes) = @_;

    my $io = Test::WWW::Hetzner::MockIO->new(
        routes   => \%routes,
        base_url => 'https://api.hetzner.cloud/v1',
    );

    return WWW::Hetzner::Cloud->new(
        token => 'test-token',
        io    => $io,
    );
}

sub mock_storage {
    my (%routes) = @_;

    # Storage is optional while its feature branch is under construction.  Keep
    # the shared mock harness loadable for the existing Cloud and Robot suites.
    require WWW::Hetzner::Storage;

    my $io = Test::WWW::Hetzner::MockIO->new(
        routes   => \%routes,
        base_url => 'https://api.hetzner.com/v1',
    );

    return WWW::Hetzner::Storage->new(
        token => 'test-token',
        io    => $io,
    );
}

sub mock_robot {
    my (%routes) = @_;

    my $io = Test::WWW::Hetzner::MockIO->new(
        routes   => \%routes,
        base_url => 'https://robot-ws.your-server.de',
    );

    return WWW::Hetzner::Robot->new(
        user     => 'test-user',
        password => 'test-password',
        io       => $io,
    );
}

1;
