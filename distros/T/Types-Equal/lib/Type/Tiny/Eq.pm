package Type::Tiny::Eq;
use strict;
use warnings;

our $VERSION = "0.03";

use parent qw( Type::Tiny );

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

sub new {
    my $class = shift;

    my %opts = ( @_ == 1 ) ? %{ $_[0] } : @_;

    _croak "Eq type constraints cannot have a parent constraint passed to the constructor"
        if exists $opts{parent};

    _croak "Eq type constraints cannot have a constraint coderef passed to the constructor"
        if exists $opts{constraint};

    _croak "Eq type constraints cannot have a inlining coderef passed to the constructor"
        if exists $opts{inlined};

    _croak "Need to supply value" unless exists $opts{value};

    _croak "Eq value must be defined" unless defined $opts{value};

    $opts{value} = "$opts{value}"; # stringify

    return $class->SUPER::new( %opts );
}

sub value { $_[0]{value} }

sub _build_display_name {
    my $self = shift;
    sprintf( "Eq['%s']", $self->value );
}

sub has_parent {
    !!0;
}

sub constraint { $_[0]{constraint} ||= $_[0]->_build_constraint }

sub _build_constraint {
    my $self = shift;
    return sub {
        defined $_ && $_ eq $self->value;
    };
}

sub can_be_inlined {
    !!1;
}

sub inline_check {
    my $self = shift;

    my $value = $self->value;
    my $code = "(defined($_[0]) && $_[0] eq '$value')";

    return "do { $Type::Tiny::SafePackage $code }"
        if $Type::Tiny::AvoidCallbacks; ## no critic (Variables::ProhibitPackageVars)
    return $code;
}

1;
__END__

=encoding utf-8

=head1 NAME

Type::Tiny::Eq - type constraint for single string equality

=head1 SYNOPSIS

    use Type::Tiny::Eq;

    my $Foo = Type::Tiny::Eq->new( value => 'foo' );
    $Foo->check('foo'); # true
    $Foo->check('bar'); # false

    Type::Tiny::Eq->new( value => undef ); # dies

=head1 DESCRIPTION

This package inherits from Type::Tiny; see that for most documentation. Major differences are listed below:

=head2 Attributes

=over

=item C<value>

Allowable value string. Non-string values (e.g. objects with
overloading) will be stringified in the constructor.

=back

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kfly@cpan.orgE<gt>

=cut

