package Yancy::Util;
our $VERSION = '1.018';
# ABSTRACT: Utilities for Yancy

#pod =head1 SYNOPSIS
#pod
#pod     use Yancy::Util qw( load_backend );
#pod     my $be = load_backend( 'test://localhost', $collections );
#pod
#pod     use Yancy::Util qw( curry );
#pod     my $helper = curry( \&_helper_sub, @args );
#pod
#pod     use Yancy::Util qw( currym );
#pod     my $sub = currym( $object, 'method_name', @args );
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
use Scalar::Util qw( blessed );
our @EXPORT_OK = qw( load_backend curry currym );

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
#pod See L<Yancy::Help::Config/Database Backend> for information about
#pod backend URLs and L<Yancy::Backend> for more information about backend
#pod objects.
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

#pod =sub curry
#pod
#pod     my $curried_sub = curry( $sub, @args );
#pod
#pod Return a new subref that, when called, will call the passed-in subref with
#pod the passed-in C<@args> first.
#pod
#pod For example:
#pod
#pod     my $add = sub {
#pod         my ( $lop, $rop ) = @_;
#pod         return $lop + $rop;
#pod     };
#pod     my $add_four = curry( $add, 4 );
#pod     say $add_four->( 1 ); # 5
#pod     say $add_four->( 2 ); # 6
#pod     say $add_four->( 3 ); # 7
#pod
#pod This is more-accurately called L<partial
#pod application|https://en.wikipedia.org/wiki/Partial_application>, but
#pod C<curry> is shorter.
#pod
#pod =cut

sub curry {
    my ( $sub, @args ) = @_;
    return sub { $sub->( @args, @_ ) };
}

#pod =sub currym
#pod
#pod     my $curried_sub = currym( $obj, $method, @args );
#pod
#pod Return a subref that, when called, will call given C<$method> on the
#pod given C<$obj> with any passed-in C<@args> first.
#pod
#pod See L</curry> for an example.
#pod
#pod =cut

sub currym {
    my ( $obj, $meth, @args ) = @_;
    my $sub = $obj->can( $meth )
        || die sprintf q{Can't curry method "%s" on object of type "%s": Method is not implemented},
            $meth, blessed( $obj );
    return curry( $sub, $obj, @args );
}
1;

__END__

=pod

=head1 NAME

Yancy::Util - Utilities for Yancy

=head1 VERSION

version 1.018

=head1 SYNOPSIS

    use Yancy::Util qw( load_backend );
    my $be = load_backend( 'test://localhost', $collections );

    use Yancy::Util qw( curry );
    my $helper = curry( \&_helper_sub, @args );

    use Yancy::Util qw( currym );
    my $sub = currym( $object, 'method_name', @args );

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

See L<Yancy::Help::Config/Database Backend> for information about
backend URLs and L<Yancy::Backend> for more information about backend
objects.

=head2 curry

    my $curried_sub = curry( $sub, @args );

Return a new subref that, when called, will call the passed-in subref with
the passed-in C<@args> first.

For example:

    my $add = sub {
        my ( $lop, $rop ) = @_;
        return $lop + $rop;
    };
    my $add_four = curry( $add, 4 );
    say $add_four->( 1 ); # 5
    say $add_four->( 2 ); # 6
    say $add_four->( 3 ); # 7

This is more-accurately called L<partial
application|https://en.wikipedia.org/wiki/Partial_application>, but
C<curry> is shorter.

=head2 currym

    my $curried_sub = currym( $obj, $method, @args );

Return a subref that, when called, will call given C<$method> on the
given C<$obj> with any passed-in C<@args> first.

See L</curry> for an example.

=head1 SEE ALSO

L<Yancy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
