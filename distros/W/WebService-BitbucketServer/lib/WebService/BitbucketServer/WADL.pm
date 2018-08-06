package WebService::BitbucketServer::WADL;
# ABSTRACT: Subroutines for parsing WADL and generating Bitbucket Server REST APIs

use warnings;
use strict;

our $VERSION = '0.605'; # VERSION

use WebService::BitbucketServer::Spec qw(api_info documentation_url package_name sub_name);

use Exporter qw(import);
use namespace::clean -except => [qw(import)];

our @EXPORT_OK = qw(parse_wadl generate_package generate_submap);


sub _croak { require Carp; Carp::croak(@_) }


sub parse_wadl {
    my $wadl_raw = shift;

    require XML::LibXML;
    require XML::LibXML::XPathContext;

    my $wadl    = XML::LibXML->load_xml(string => \$wadl_raw);
    my $xpc     = XML::LibXML::XPathContext->new($wadl);

    $xpc->registerNs(xhtml => 'http://www.w3.org/1999/xhtml');

    my $application;

    for my $ns (qw{http://wadl.dev.java.net/2009/02 http://research.sun.com/wadl/2006/10}) {
        $xpc->registerNs(wadl => $ns);
        ($application) = $xpc->findnodes('/wadl:application');
        last if $application;
    }

    die 'No wadl:application found' if !$application;

    my @endpoints = _handle_application($application, $xpc);
    return \@endpoints;
}

sub _handle_application {
    my ($node, $xpc) = @_;

    my @endpoints;
    my @params = _handle_param($node, $xpc);

    for my $resources ($xpc->findnodes('wadl:resources', $node)) {
        push @endpoints, _handle_resources($resources, $xpc, \@params);
    }

    return @endpoints;
}

sub _handle_resources {
    my ($node, $xpc, $params) = @_;

    my @endpoints;
    my @params = _handle_param($node, $xpc);

    for my $resource ($xpc->findnodes('wadl:resource', $node)) {
        push @endpoints, _handle_resource($resource, $xpc, '', [@$params, @params]);
    }

    return @endpoints;
}

sub _handle_resource {
    my ($node, $xpc, $path, $params) = @_;

    my $xpath = $node->nodePath;

    my $path_part = $node->getAttribute('path');
    $path_part =~ s!^/+!!;
    $path_part =~ s!/+$!!;

    $path = join('/', $path ? $path : (), $path_part ? $path_part : ());

    my @endpoints;
    my @params = _handle_param($node, $xpc);

    for my $method ($xpc->findnodes('wadl:method', $node)) {
        push @endpoints, _handle_method($method, $xpc, $path, [@$params, @params]);
    }

    for my $resource ($xpc->findnodes('wadl:resource', $node)) {
        # go deep
        push @endpoints, _handle_resource($resource, $xpc, $path, [@$params, @params]);
    }

    return @endpoints;
}

sub _handle_method {
    my ($node, $xpc, $path, $params) = @_;

    my $name = $node->getAttribute('name') or die 'Method with no name?';
    my $id = $node->getAttribute('id');

    my @params = _handle_param($node, $xpc, 'wadl:request/wadl:param');
    my @representations = _handle_representation($node, $xpc, 'wadl:response/wadl:representation');

    my $endpoint = {
        path            => $path,
        method          => $name,
        id              => $id,
        params          => [@$params, @params],
        representations => [@representations],
        doc             => _handle_doc($node, $xpc),
    };

    return $endpoint;
}

sub _handle_param {
    my ($node, $xpc, $xpath) = @_;

    $xpath ||= 'wadl:param';

    my @params;

    for my $param ($xpc->findnodes($xpath, $node)) {
        my $name        = $param->getAttribute('name');
        my $required    = lc($param->getAttribute('required') || '') eq 'true';
        my $repeating   = lc($param->getAttribute('repeating') || '') eq 'true';

        push @params, {
            name        => $name,
            style       => $param->getAttribute('style'),
            type        => $param->getAttribute('type') || 'xsd:string',
            default     => $param->getAttribute('default'),
            required    => $required,
            repeating   => $repeating,
            fixed       => $param->getAttribute('fixed'),
            doc         => _handle_doc($param, $xpc),
        };
    }

    return @params;
}

sub _handle_representation {
    my ($node, $xpc, $xpath) = @_;

    $xpath ||= 'wadl:representation';

    my @representations;

    for my $representation ($xpc->findnodes($xpath, $node)) {
        my $status = $representation->parentNode->getAttribute('status') || $representation->getAttribute('status');
        my $type = $representation->getAttribute('mediaType');
        my $element = $representation->getAttribute('element');

        push @representations, {
            status  => $status,
            type    => $type,
            element => $element,
            doc     => _handle_doc($representation, $xpc),
        };
    }

    return @representations;
}

sub _handle_doc {
    my ($node, $xpc) = @_;

    my $documentation = '';

    for my $doc ($xpc->findnodes('wadl:doc[not(descendant::xhtml:p)]', $node)) {
        $documentation .= $doc->to_literal;
    }

    return $documentation;
}


sub generate_submap {
    my $wadl = shift;

    my $api_info    = api_info($wadl) or _croak('Cannot get API info from WADL');
    my $api         = package_name($wadl) or _croak('Cannot determine package name from WADL');
    my $method      = $api_info->{id};

    my $out;
    $out .= "# Map endpoints to subroutine names in $api.\nuse strict;\n{\n";

    my %seen_endpoint;
    my %seen_subname;

    for my $endpoint (sort { $a->{path} cmp $b->{path} || $a->{method} cmp $b->{method} } @$wadl) {
        my $subname = sub_name($endpoint);
        my $key = "$endpoint->{path} $endpoint->{method}";

        if ($seen_endpoint{$key}) {
            warn "Duplicate endpoint: $key\n";
            next;
        }

        $out .= "    '$key' => '$subname',\n";

        if (!$subname) {
            chomp $out;
            $out .= " # Disabled\n";
        }
        elsif ($seen_subname{$subname}) {
            chomp $out;
            $out .= " # TO"."DO - Fix this duplicate name.\n";
        }

        $seen_endpoint{$key} = $endpoint;
        $seen_subname{$subname} = $endpoint;
    }

    while (my ($key, $subname) = each %{$WebService::BitbucketServer::Spec::SUBMAP{$api_info->{id}}}) {
        next if $seen_endpoint{$key};

        $out .= "    '$key' => '$subname', # Unused\n";
    }

    $out .= "};\n";

    return $out;
}


sub generate_package {
    my $wadl = shift;
    my $args = @_ == 1 ? shift : {@_};

    my $api_info    = api_info($wadl) or _croak('Cannot get API info from WADL');
    my $api         = package_name($wadl) or _croak('Cannot determine package name from WADL');
    my $method      = $api_info->{id};
    my $package     = $args->{package} || "$args->{base}::${api}";
    my $abstract    = $args->{abstract} || 'Bindings for a Bitbucket Server REST API';
    my $doc_url     = $args->{documentation_url} || documentation_url($wadl->[0], 'html', $args->{version});
    my $generated   = 'Generated by ' . __PACKAGE__ . ' - DO NOT EDIT!';

    my %swap = (
        api         => $api,
        version     => $args->{version},
        method      => $method,
        package     => $package,
        abstract    => $abstract,
        doc_url     => $doc_url,
        generated   => $generated,
        pod         => !$args->{no_pod},
    );

    my $preamble = _template(<<'END', %swap);
# [% generated %]
package [% package %];
# ABSTRACT: [% abstract %]

[% IF pod %]
[% IF method %]
=head1 SYNOPSIS

    my $stash = WebService::BitbucketServer->new(
        base_url    => 'https://stash.example.com/',
        username    => 'bob',
        password    => 'secret',
    );
    my $api = $stash->[% method %];

[% END %]
=head1 DESCRIPTION

This is a Bitbucket Server REST API for L<[% api %]|[% doc_url %]>.

Original API documentation created by and copyright Atlassian.

=cut
[% END %]

use warnings;
use strict;

our $VERSION = '9999.999'; # VERSION

use Moo;
use namespace::clean;

[% IF pod %]
=head1 ATTRIBUTES

=head2 context

Get the instance of L<WebService::BitbucketServer> passed to L</new>.

=cut
[% END %]

has context => (
    is          => 'ro',
    isa         => sub { die 'Not a WebService::BitbucketServer' if !$_[0]->isa('WebService::BitbucketServer'); },
    required    => 1,
);

[% IF pod %]
=head1 METHODS

=head2 new

    $api = [% package %]->new(context => $webservice_bitbucketserver_obj);

Create a new API.

[% IF method %]
Normally you would use C<<< $webservice_bitbucketserver_obj->[% method %] >>> instead.

[% END %]
=cut
[% END %]

sub _croak { require Carp; Carp::croak(@_) }

sub _get_url {
    my $url  = shift;
    my $args = shift || {};
    $url =~ s/\{([^:}]+)(?::\.\*)?\}/_get_path_parameter($1, $args)/eg;
    return $url;
}

sub _get_path_parameter {
    my $name = shift;
    my $args = shift || {};
    return delete $args->{$name} if defined $args->{$name};
    $name =~ s/([A-Z])/'_'.lc($1)/eg;
    return delete $args->{$name} if defined $args->{$name};
    _croak("Missing required parameter $name");
}
END

    my $postamble = _template(<<'END', %swap);
[% IF pod %]
=head1 SEE ALSO

=over 4

=item * L<WebService::BitbucketServer>

=item * L<https://developer.atlassian.com/bitbucket/server/docs/latest/>

=back

=cut
[% END %]

1;
END

    my @subs;

    my %seen;

    my %method_order = (
        POST    => 0,
        GET     => 1,
        PUT     => 2,
        PATCH   => 3,
        DELETE  => 4,
    );

    for my $endpoint (sort { $a->{path} cmp $b->{path} ||
            ($method_order{$a->{method}} || 99) <=> ($method_order{$a->{method}} || 99) } @$wadl) {
        # fix paths that have 2+ slash separators
        $endpoint->{path} =~ s!/+!/!g;

        my $sub_name = sub_name($endpoint);
        next if !$sub_name || $seen{$sub_name};

        # TODO - combine duplicate endpoints instead of skipping them
        $seen{$sub_name} = 1;

        # documentation
        my $pod = $args->{no_pod} ? '' : _endpoint_pod($endpoint, $sub_name);

        my %swap = (
            subname => $sub_name,
            path    => $endpoint->{path},
            method  => $endpoint->{method},
            pod     => $pod,
        );
        my $code = _template(<<'END', %swap);
[% pod %]

sub [% subname %] {
    my $self = shift;
    my $args = {@_ == 1 ? %{$_[0]} : @_};
    my $url  = _get_url('[% path %]', $args);
    my $data = (exists $args->{data} && $args->{data}) || (%$args && $args);
    $self->context->call(method => '[% method %]', url => $url, $data ? (data => $data) : ());
}
END
        push @subs, $code;
    }

    my $modcode = join("\n", $preamble, @subs, $postamble);
    return wantarray ? ($modcode, $package) : $modcode;
}

# ghetto templates
sub _template {
    my $text = shift;
    my %swap = @_;
    $text =~ s/
        \[\% \s* IF \s* ([A-Za-z_]+) \s* \%\]
        \n?
        ((?:.*?(?R)?.*?)+)
        \n?
        \[\% \s* END \s* \%\]
    /$swap{$1} ? _template($2, %swap) : ''/xsge;
    $text =~ s/\[\%\s*([A-Za-z_]+)\s*\%\]/$swap{$1} || ''/ge;
    return $text;
}

# generate pod documentation for an endpoint
sub _endpoint_pod {
    my $endpoint = shift;
    my $sub_name = shift || $endpoint->{id};

    my $pod = "=head2 $sub_name\n\n";

    $pod .= _html_to_pod($endpoint->{doc} || '');
    $pod .= "\n\n    $endpoint->{method} $endpoint->{path}\n\n";

    if (@{$endpoint->{params} || []}) {
        $pod .= "Parameters:\n\n=over 4\n\n";
        for my $param (@{$endpoint->{params} || []}) {
            my $name    = $param->{name};
            my $type    = $param->{type} || 'string';
            my $default = $param->{default} || 'none';

            $type =~ s/^\w+://;
            my $line = "$type, default: $default";

            $pod .= "=item * C<<< $name >>> - $line\n\n";
            $pod .= _html_to_pod($param->{doc}) . "\n\n" if $param->{doc};
        }
        $pod .= "=back\n\n";
    }

    if (grep { $_->{status} } @{$endpoint->{representations} || []}) {
        $pod .= "Responses:\n\n=over 4\n\n";
        for my $rep (@{$endpoint->{representations} || []}) {
            next if !$rep->{status};
            my $element = $rep->{element} || 'data';
            my $type    = $rep->{type} || 'unknown';

            $element =~ s/^\w+://;
            my $line = "$element, type: $type";

            $pod .= "=item * C<<< $rep->{status} >>> - $line\n\n";
            $pod .= _html_to_pod($rep->{doc}) . "\n\n" if $rep->{doc};
        }
        $pod .= "=back\n\n";
    }

    # collapse blank lines and trim
    $pod =~ s!\n{2,}!\n\n!g;
    $pod =~ s!^\s+!!;
    $pod =~ s!\s+$!!;

    $pod .= "\n\n=cut";

    return $pod;
}

sub _format_preformatted {
    my $text = shift;

    my $formatted = eval {
        require JSON::MaybeXS;
        my $json = JSON::MaybeXS->new(canonical => 1, pretty => 1, utf8 => 1);
        $json->encode($json->decode($text));
    } || $text;

    return join("\n", map { "    $_" } split(/\n/, $formatted));
}

# convert some *very* simple HTML to pod
sub _html_to_pod {
    my $text = shift;

    my $B = '(?:b|strong)';
    my $I = '(?:em|i|u)';
    my $C = '(?:code|kbd|tt)';

    # all somehow without any recursive regexps...
    $text =~ s!^\s+!!mg;
    $text =~ s!<h(\d)>(.+?)</h(?1)>!\n\n=head$1 $2\n\n!sig;
    $text =~ s!<$B>(.+?)</$B>!B<<< $1 >>>!sig;
    $text =~ s!<$I>(.+?)</$I>!I<<< $1 >>>!sig;
    $text =~ s!<$C>(.+?)</$C>!C<<< $1 >>>!sig;
    $text =~ s!<a href="([^"]+)">(.+?)</a>!L<<< $2|$1 >>>!sig;
    $text =~ s!</?p>!\n\n!ig;
    $text =~ s!<u[li]>!\n\n=over 4\n\n!ig;
    $text =~ s!</u[li]>!\n\n=back\n\n!ig;
    $text =~ s!<li>!\n\n=item *\n\n!ig;
    $text =~ s!</li>!!ig;
    $text =~ s!<pre>\s*(.+?)\s*</pre>!"\n" . _format_preformatted($1) . "\n\n"!sige;

    # handle other weird markup in the WADL docs:
    $text =~ s!\{\@code ([^}]+)\}!C<<< $1 >>>!ig;
    $text =~ s!\{\@link (?:[A-Za-z0-9#]+)(?:\([^)]*\))? ([^}]+)\}!$1!ig;

    # remove trailing whitespace:
    $text =~ s!\h+\n!\n!sg;

    return $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::BitbucketServer::WADL - Subroutines for parsing WADL and generating Bitbucket Server REST APIs

=head1 VERSION

version 0.605

=head1 FUNCTIONS

=head2 parse_wadl

    $api_spec = parse_wadl($wadl);

Parse a string as WADL to get an arrayref of endpoints.

=head2 generate_submap

    my $code = generate_submap($wadl);

Generate a perl script that returns a mapping between endpoints and subroutine
names.

=head2 generate_package

    my $code = generate_package($package_name, $wadl);
    my $code = generate_package($package_name, $wadl, \%options);

Generate the code (with optional documentation) for the endpoints specified in
the WADL structure.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/WebService-BitbucketServer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
