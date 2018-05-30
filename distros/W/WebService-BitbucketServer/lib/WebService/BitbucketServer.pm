package WebService::BitbucketServer;
# ABSTRACT: Bindings for Bitbucket Server REST APIs


use warnings;
use strict;

our $VERSION = '0.604'; # VERSION

use HTTP::AnyUA::Util qw(www_form_urlencode);
use HTTP::AnyUA;
use Module::Load qw(load);
use Scalar::Util qw(weaken);
use Types::Standard qw(Bool Object Str);
use WebService::BitbucketServer::Response;
use WebService::BitbucketServer::Spec qw(api_info documentation_url);

use Moo;
use namespace::clean;

sub _croak { require Carp; Carp::croak(@_) }
sub _usage { _croak("Usage: @_\n") }

sub _debug_log { print STDERR join(' ', @_), "\n" if $ENV{PERL_WEBSERVICE_BITBUCKETSERVER_DEBUG} }


has base_url => (
    is          => 'ro',
    isa         => Str,
    required    => 1,
);


has path => (
    is      => 'lazy',
    isa     => Str,
    default => 'rest',
);


has [qw(username password)] => (
    is  => 'ro',
    isa => Str,
);


has ua => (
    is      => 'lazy',
    default => sub {
        load HTTP::Tiny;
        HTTP::Tiny->new(
            agent   => "perl-webservice-bitbucketserver/$VERSION",
        );
    },
);


has any_ua => (
    is      => 'lazy',
    isa     => Object,
    default => sub {
        my $self = shift;
        HTTP::AnyUA->new(ua => $self->ua);
    },
);


has json => (
    is      => 'lazy',
    isa     => Object,
    default => sub {
        load JSON;
        JSON->new->utf8(1);
    },
);


has no_security_warning => (
    is      => 'rwp',
    isa     => Bool,
    lazy    => 1,
    default => sub { $ENV{PERL_WEBSERVICE_BITBUCKETSERVER_NO_SECURITY_WARNING} || 0 },
);


my %api_accessors;
while (my ($namespace, $api) = each %WebService::BitbucketServer::Spec::API) {
    my $method  = $api->{id};
    my $package = __PACKAGE__ . '::' . $api->{package};

    next if $api_accessors{$method};
    $api_accessors{$method} = 1;

    no strict 'refs';   ## no critic ProhibitNoStrict
    *{__PACKAGE__."::${method}"} = sub {
        my $self = shift;
        return $self->{$method} if defined $self->{$method};
        load $package;
        my $api = $package->new(context => $self);
        $self->{$method} = $api;
        weaken($self->{$method});
        return $api;
    };
};


sub url {
    my $self = shift;
    my $base = $self->base_url;
    my $path = $self->path;
    $base =~ s!/+$!!;
    $path =~ s!^/+!!;
    return "$base/$path";
}


sub call {
    my $self = shift;
    (@_ == 1 && ref($_[0]) eq 'HASH') || @_ % 2 == 0
        or _usage(q{$api->call(method => $method, url => $url, %options)});
    my $args = @_ == 1 ? shift : {@_};

    $args->{url} or _croak("url is required\n");

    my $method  = $args->{method} || 'GET';
    my $url     = join('/', $self->url, $args->{url});

    my %options;
    $options{headers}{Accept} = '*/*;q=0.2,application/json';       # prefer json response

    $self->_call_add_authorization($args, \%options);

    # request body
    my $data        = $args->{data};
    my $data_type   = $args->{data_type} || 'application/json';
    if ($data) {
        if ($method eq 'GET' || $method eq 'HEAD') {
            my $params  = ref($data) ? www_form_urlencode($data) : $data;
            my $sep     = $url =~ /\?/ ? '&' : '?';
            $url .= "${sep}${params}";
        }
        else {
            if ($data_type eq 'application/json' && ref($data)) {
                $data = $self->json->encode($data);
            }
            $options{content} = $data;
            $options{headers}{'content-type'}   = $data_type;
            $options{headers}{'content-length'} = length $data;
        }
    }

    my $handle_response = sub {
        my $resp = shift;

        return $resp if $args->{raw};

        return WebService::BitbucketServer::Response->new(
            context         => $self,
            request_args    => $args,
            raw             => $resp,
            json            => $self->json,
        );
    };

    my $resp = $self->any_ua->request($method, $url, \%options);

    if ($self->any_ua->response_is_future) {
        return $resp->transform(
            done => $handle_response,
            fail => $handle_response,
        );
    }
    else {
        return $handle_response->($resp);
    }
}

# add the authorization header to request options
sub _call_add_authorization {
    my $self = shift;
    my $args = shift;
    my $opts = shift;

    if ($self->username && $self->password) {
        my $url = $self->base_url;
        if (!$self->no_security_warning && $url !~ /^https/) {
            warn "Bitbucket Server authorization is being transferred unencrypted to $url !!!\n";
            $self->_set_no_security_warning(0);
        }

        my $payload = $self->username . ':' . $self->password;
        require MIME::Base64;
        my $auth_token = MIME::Base64::encode_base64($payload, '');
        $opts->{headers}{'authorization'} = "Basic $auth_token";
    }
}


sub write_api_packages {
    my $self = shift;
    (@_ == 1 && ref($_[0]) eq 'HASH') || @_ % 2 == 0
        or _usage(q{$api->write_api_packages(%args)});
    my $args = @_ == 1 ? shift : {@_};

    $self = __PACKAGE__->new(base_url => '') unless ref $self;

    require WebService::BitbucketServer::WADL;

    my $handle_response = sub {
        my $resp = shift;

        if (!$resp->{success}) {
            warn "Failed to fetch $resp->{url} - $resp->{status} $resp->{reason}\n";
            return;
        }

        $self->_debug_log('Fetched WADL', $resp->{url});

        my $wadl = WebService::BitbucketServer::WADL::parse_wadl($resp->{content});

        my $api_info = api_info($wadl);
        if (!$api_info) {
            warn "Missing API info: $resp->{url}\n";
            return;
        }

        my ($package_code, $package) = WebService::BitbucketServer::WADL::generate_package($wadl, %$args, base => __PACKAGE__);

        require File::Path;
        require File::Spec;

        my @pm  = ($args->{dir} ? $args->{dir} : (), _mod_to_pm($package));
        my $pm  = File::Spec->catfile(@pm);
        my $dir = File::Spec->catdir(@pm[0 .. (scalar @pm - 2)]);

        File::Path::make_path($dir);

        # write the pm
        open(my $fh, '>', $pm) or die "open failed ($pm): $!";
        print $fh $package_code;
        close($fh);

        my $submap = WebService::BitbucketServer::WADL::generate_submap($wadl, %$args);

        my $filename = "submap_$api_info->{id}.pl";

        my $filepath = File::Spec->catfile(qw{shares spec}, $filename);
        $dir = File::Spec->catdir(qw{shares spec});

        File::Path::make_path($dir);

        # write the subroutine map
        open($fh, '>', $filepath) or die "open failed ($filepath): $!";
        print $fh $submap;
        close($fh);
    };

    my @responses;
    my %requested;

    for my $namespace (keys %WebService::BitbucketServer::Spec::API) {
        my $url  = documentation_url($namespace, 'wadl', $args->{version});

        next if $requested{$url};
        $requested{$url} = 1;

        my $resp = $self->any_ua->get($url);
        if ($self->any_ua->response_is_future) {
            push @responses, $resp->transform(
                done => $handle_response,
                fail => $handle_response,
            );
        }
        else {
            push @responses, $handle_response->($resp);
        }
    }

    if ($self->any_ua->response_is_future) {
        return Future->wait_all(@responses);
    }
    else {
        return \@responses;
    }
}

sub _mod_to_pm {
    my $mod = shift;
    my @parts = split(/::/, $mod);
    $parts[-1] = "$parts[-1].pm";
    return @parts;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::BitbucketServer - Bindings for Bitbucket Server REST APIs

=head1 VERSION

version 0.604

=head1 SYNOPSIS

    my $api = WebService::BitbucketServer->new(
        base_url    => 'https://stash.example.com/',
        username    => 'bob',
        password    => 'secret',
    );

    my $response = $api->core->get_application_properties;
    my $app_info = $response->data;
    print "Making API calls to: $app_info->{displayName} $app_info->{version}\n";

    # Or use the low-level method (useful perhaps for new endpoints
    # that are not packaged yet):

    my $response = $api->call(method => 'GET', url => 'api/1.0/application-properties');

    # You can also use your own user agent:

    my $api = WebService::BitbucketServer->new(
        base_url    => 'https://stash.example.com/',
        username    => 'bob',
        password    => 'secret',
        ua          => Mojo::UserAgent->new,
    );

    # If the user agent is nonblocking, responses are Futures:

    my $future = $api->core->get_application_properties;
    $future->on_done(sub {
        my $app_info = shift->data;
        print "Making API calls to: $app_info->{displayName} $app_info->{version}\n";
    });

=head1 DESCRIPTION

This is the main module for the Bitbucket Server API bindings for Perl.

=head1 ATTRIBUTES

=head2 base_url

Get the base URL of the Bitbucket Server host.

=head2 path

Get the path from the base URL to the APIs. Defaults to "rest".

=head2 username

Get the username of the user for authenticating.

=head2 password

Get the password of the user for authenticating.

=head2 ua

Get the user agent used to make API calls.

Defaults to L<HTTP::Tiny>.

Because this API module uses L<HTTP::AnyUA> under the hood, you can actually use any user agent
supported by HTTP::AnyUA.

=head2 any_ua

Get the L<HTTP::AnyUA> object.

=head2 json

Get the L<JSON> (or compatible) object used for encoding and decoding documents.

=head2 no_security_warning

Get whether or not a warning will be issued when an insecure action takes place (such as sending
credentials unencrypted). Defaults to false (i.e. will issue warning).

=head1 METHODS

=head2 new

    $api = WebService::BitbucketServer->new(base_url => $base_url, %other_attributes);

Create a new API context object. Provide L</ATTRIBUTES> to customize.

=head2 core

Get the L<WebService::BitbucketServer::Core::V1> api.

=head2 access_tokens

Get the L<WebService::BitbucketServer::AccessTokens::V1> api.

=head2 audit

Get the L<WebService::BitbucketServer::Audit::V1> api.

=head2 ref_restriction

Get the L<WebService::BitbucketServer::RefRestriction::V2> api.

=head2 branch

Get the L<WebService::BitbucketServer::Branch::V1> api.

=head2 build

Get the L<WebService::BitbucketServer::Build::V1> api.

=head2 comment_likes

Get the L<WebService::BitbucketServer::CommentLikes::V1> api.

=head2 default_reviewers

Get the L<WebService::BitbucketServer::DefaultReviewers::V1> api.

=head2 git

Get the L<WebService::BitbucketServer::Git::V1> api.

=head2 gpg

Get the L<WebService::BitbucketServer::GPG::V1> api.

=head2 jira

Get the L<WebService::BitbucketServer::JIRA::V1> api.

=head2 ssh

Get the L<WebService::BitbucketServer::SSH::V1> api.

=head2 mirroring_upstream

Get the L<WebService::BitbucketServer::MirroringUpstream::V1> api.

=head2 repository_ref_sync

Get the L<WebService::BitbucketServer::RepositoryRefSync::V1> api.

=head2 url

    $url = $api->url;

Get the URL of the APIs (a combination of L</base_url> and L</path>).

=head2 call

    $response = $api->call(method => $method, url => $url, %options);

Make a request to an API and get a L<response|WebService::BitbucketServer::Response> (or L<Future>
if the user agent is non-blocking).

=over 4

=item *

url - the endpoint URL, relative to L</url>

=item *

method - the HTTP method

=item *

data - request data

=item *

data_type - type of request data, if any (defaults to "application/json")

=item *

raw - get a hashref response instead of a L<WebService::BitbucketServer::Response>

=back

=head2 write_api_packages

    WebService::BitbucketServer->write_api_packages;
    WebService::BitbucketServer->write_api_packages(dir => 'lib');

Download API specifications from L<https://developer.atlassian.com> and generate packages for
them, writing them to the specified directory. You normally don't need this because this module
ships with pre-built APIs, but you can use this to generate other APIs or versions if needed.

Requires L<XML::LibXML>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/WebService-BitbucketServer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 CONTRIBUTOR

=for stopwords Camspi

Camspi <amarus18@hotmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
