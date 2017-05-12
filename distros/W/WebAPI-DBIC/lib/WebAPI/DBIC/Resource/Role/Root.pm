package WebAPI::DBIC::Resource::Role::Root;
$WebAPI::DBIC::Resource::Role::Root::VERSION = '0.004002';

use Moo::Role;


requires 'encode_json';


has content_types_provided => (
    is => 'lazy',
);

sub _build_content_types_provided {
    return [
        { 'application/vnd.wapid+json' => 'to_plain_json' },
        { 'text/html' => 'to_html' }, # provide redirect to HAL browser
    ]
}


sub allowed_methods { return [ qw(GET HEAD) ] }


sub to_html {
    my $self = shift;
    my $env = $self->request->env;
    my $router = $env->{'plack.router'};
    my $path   = $env->{REQUEST_URI}; # "/clients/v1/";
    # XXX this location should not be hard-coded
    $self->response->header(Location => "browser/browser.html#$path");
    return \302;
}


sub to_plain_json {
    return $_[0]->encode_json($_[0]->render_root_as_plain());
}


sub render_root_as_plain { # informal JSON description, XXX liable to change
    my ($self) = @_;

    my $request = $self->request;
    my $path = $request->env->{REQUEST_URI}; # "/clients/v1/";
    my %links;
    foreach my $route (@{$self->router->routes})  {
        my @parts;

        for my $c (@{ $route->components }) {
            if ($route->is_component_variable($c)) {
                push @parts, ":".$route->get_component_name($c);
            } else {
                push @parts, "$c";
            }
        }
        next unless @parts;

        my $url = $path . join("/", @parts);
        die "Duplicate path: $url" if $links{$url};
        my $title = join(" ", (split /::/, $route->defaults->{result_class})[-3,-1]);
        $links{$url} = $title;
    }

    return {
        routes => \%links,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::Role::Root

=head1 VERSION

version 0.004002

=head1 DESCRIPTION

Handles GET and HEAD requests for requests representing the root resource, e.g. C</>.

Supports the C<application/json> content type.

=head1 NAME

WebAPI::DBIC::Resource::Role::Root - methods to handle requests for the root resource

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
