package Yukki::Web::Router::Route;
{
  $Yukki::Web::Router::Route::VERSION = '0.140290';
}
use Moose;

extends 'Path::Router::Route';

use Yukki::Types qw( AccessLevel );
use Yukki::Web::Router::Route::Match;

use MooseX::Types::Moose qw( ArrayRef HashRef );
use MooseX::Types::Structured qw( Tuple );
use List::MoreUtils qw( any );

# ABSTRACT: Adds ACLs to routes


has acl => (
    is          => 'ro',
    isa         => ArrayRef[Tuple[AccessLevel,HashRef]],
    required    => 1,
);


sub is_component_slurpy {
    my ($self, $component) = @_;
    $component =~ /^[+*]:/;
}


sub is_component_optional {
    my ($self, $component) = @_;
    $component =~ /^[?*]:/;
}


sub is_component_variable {
    my ($self, $component) = @_;
    $component =~ /^[?*+]?:/;
}


sub get_component_name {
    my ($self, $component) = @_;
    my ($name) = ($component =~ /^[?*+]?:(.*)$/);
    return $name;
}


sub has_slurpy_match {
    my $self = shift;
    return any { $self->is_component_slurpy($_) } reverse @{ $self->components };
}


sub create_default_mapping {
    my $self = shift;

    my %defaults = %{ $self->defaults };
    for my $key (keys %defaults) {
        if (ref $defaults{$key} eq 'ARRAY') {
            $defaults{$key} = [ @{ $defaults{$key} } ];
        }
    }

    return \%defaults;
}


sub match {
    my ($self, $parts) = @_;

    return unless (
        @$parts >= $self->length_without_optionals &&
        ($self->has_slurpy_match || @$parts <= $self->length)
    );

    my @parts = @$parts; # for shifting

    my $mapping = $self->has_defaults ? $self->create_default_mapping : {};

    for my $c (@{ $self->components }) {
        unless (@parts) {
            die "should never get here: " .
                "no \@parts left, but more required components remain"
                if ! $self->is_component_optional($c);
            last;
        }

        my $part;
        if ($self->is_component_slurpy($c)) {
            $part = [ @parts ];
            @parts = ();
        }
        else {
            $part = shift @parts;
        }

        if ($self->is_component_variable($c)) {
            my $name = $self->get_component_name($c);

            if (my $v = $self->has_validation_for($name)) {
                return unless $v->check($part);
            }

            $mapping->{$name} = $part;
        }

        else {
            return unless $c eq $part;
        }
    }

    return Yukki::Web::Router::Route::Match->new(
        path    => join('/', @$parts),
        route   => $self,
        mapping => $mapping,
    );
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Router::Route - Adds ACLs to routes

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

Each route in L<Yukki::Web::Router> is defined using this class.

=head1 EXTENDS

L<Path::Router::Route>

=head1 ATTRIBUTES

=head2 acl

Each route has an access control table here that defines what access levels are
required of a visitor to perform each operation.

=head1 METHODS

=head2 is_component_slurpy

If the path component is like "*:var" or "+:var", it is slurpy.

=head2 is_component_optional

If the path component is like "?:var" or "*:var", it is optional.

=head2 is_component_variable

If the path component is like "?:var" or "+:var" or "*:var" or ":var", it is a
variable.

=head2 get_component_name

Grabs the name out of a variable.

=head2 has_slurpy_match

Returns true if any component is slurpy.

=head2 create_default_mapping

If a default value is an array reference, copies that array.

=head2 match

Adds support for slurpy matching.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
