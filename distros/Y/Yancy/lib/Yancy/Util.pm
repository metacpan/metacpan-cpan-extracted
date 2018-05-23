package Yancy::Util;
our $VERSION = '1.005';
# ABSTRACT: Utilities for Yancy

#pod =head1 SYNOPSIS
#pod
#pod     use Yancy::Util qw( load_backend );
#pod     my $be = load_backend( 'test://localhost', $collections );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module contains utility functions for Yancy.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy>
#pod
#pod =cut

use Mojo::Base '-strict';
use Exporter 'import';
use Mojo::Loader qw( load_class );
our @EXPORT_OK = qw( load_backend );

#pod =sub load_backend
#pod
#pod     my $backend = load_backend( $backend_url, $collections );
#pod     my $backend = load_backend( { $backend_name => $arg }, $collections );
#pod
#pod Get a Yancy backend from the given backend URL, or from a hash reference
#pod with a backend name and optional argument. The C<$collections> hash is
#pod the configured collections for this backend.
#pod
#pod A backend URL should begin with a name followed by a colon. The first
#pod letter of the name will be capitalized, and used to build a class name
#pod in the C<Yancy::Backend> namespace.
#pod
#pod The C<$backend_name> should be the name of a module in the
#pod C<Yancy::Backend> namespace. The C<$arg> is handled by the backend
#pod module. Read your backend module's documentation for details.
#pod
#pod See L<Yancy/Database Backend> for information about backend URLs and
#pod L<Yancy::Backend> for more information about backend objects.
#pod
#pod =cut

sub load_backend {
    my ( $config, $collections ) = @_;
    my ( $type, $arg );
    if ( !ref $config ) {
        ( $type ) = $config =~ m{^([^:]+)};
        $arg = $config
    }
    else {
        ( $type, $arg ) = %{ $config };
    }
    my $class = 'Yancy::Backend::' . ucfirst $type;
    if ( my $e = load_class( $class ) ) {
        die ref $e ? "Could not load class $class: $e" : "Could not find class $class";
    }
    return $class->new( $arg, $collections );
}

1;

__END__

=pod

=head1 NAME

Yancy::Util - Utilities for Yancy

=head1 VERSION

version 1.005

=head1 SYNOPSIS

    use Yancy::Util qw( load_backend );
    my $be = load_backend( 'test://localhost', $collections );

=head1 DESCRIPTION

This module contains utility functions for Yancy.

=head1 SUBROUTINES

=head2 load_backend

    my $backend = load_backend( $backend_url, $collections );
    my $backend = load_backend( { $backend_name => $arg }, $collections );

Get a Yancy backend from the given backend URL, or from a hash reference
with a backend name and optional argument. The C<$collections> hash is
the configured collections for this backend.

A backend URL should begin with a name followed by a colon. The first
letter of the name will be capitalized, and used to build a class name
in the C<Yancy::Backend> namespace.

The C<$backend_name> should be the name of a module in the
C<Yancy::Backend> namespace. The C<$arg> is handled by the backend
module. Read your backend module's documentation for details.

See L<Yancy/Database Backend> for information about backend URLs and
L<Yancy::Backend> for more information about backend objects.

=head1 SEE ALSO

L<Yancy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
