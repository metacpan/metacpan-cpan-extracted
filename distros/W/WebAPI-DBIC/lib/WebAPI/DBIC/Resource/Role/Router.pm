package WebAPI::DBIC::Resource::Role::Router;
$WebAPI::DBIC::Resource::Role::Router::VERSION = '0.004002';

use Moo::Role;



sub uri_for { ## no critic (RequireArgUnpacking)
    my $self = shift; # %pk in @_

    my $url = $self->router->uri_for(@_)
        or return;

    my $env = $self->request->env;
    my $prefix = $env->{SCRIPT_NAME};
    return "$prefix/$url" unless wantarray;
    return ($prefix, $url);
}


sub router {
    return shift->request->env->{'plack.router'};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::Role::Router

=head1 VERSION

version 0.004002

=head1 DESCRIPTION

This role provides methods to interface with the router.

=head1 NAME

WebAPI::DBIC::Resource::Role::Router - interface with the router

=head1 METHODS

=head2 uri_for

    $absolute_url = $self->uri_for(
        resource_class => $resource_class, # e.g. 'TestSchema::Result::Artist'
        1 => $artist_id                    # key value (first and only in this case)
    );

    ($prefix_path, $relative_path) = $self->uri_for(...);

Uses the router to find a url that matches the given parameter hash.
Returns undef if there's no match.

The Plack request env hash is used to get the router ('C<plack.router>')
and the script url prefix ('C<SCRIPT_NAME>').

When called in scalar context the absolute url is returned. This is the
concatenation of the script url prefix and the relative path matched by the
router.  When called in list context the two values are returned separately.

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
