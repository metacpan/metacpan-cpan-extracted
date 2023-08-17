package Type::Tiny::NumEqu;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use parent qw( Type::Tiny );

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

sub new {
    my $class = shift;

    my %opts = ( @_ == 1 ) ? %{ $_[0] } : @_;

    _croak "NumEqu type constraints cannot have a parent constraint passed to the constructor"
        if exists $opts{parent};

    _croak "NumEqu type constraints cannot have a constraint coderef passed to the constructor"
        if exists $opts{constraint};

    _croak "NumEqu type constraints cannot have a inlining coderef passed to the constructor"
        if exists $opts{inlined};

    _croak "Need to supply value" unless exists $opts{value};

    if (defined $opts{value}) {
        use warnings FATAL => 'numeric';
        eval {
            $opts{value} = $opts{value} + 0; # numify
        };
        if ($@) {
            _croak sprintf("`%s` is not number. NumEqu value must be number.", $opts{value});
        }
    }

    return $class->SUPER::new( %opts );
}

sub value { $_[0]{value} }

sub _build_display_name {
    my $self = shift;

    defined $self->value
        ? sprintf( "NumEqu[%s]", $self->value )
        : "NumEqu[Undef]";
}

sub has_parent {
    !!0;
}

sub constraint { $_[0]{constraint} ||= $_[0]->_build_constraint }

sub _build_constraint {
    my $self = shift;

    if (defined $self->value) {
        return sub {
            defined $_ && $_ == $self->value;
        };
    }
    else {
        return sub {
            !defined $_;
        };
    }
}

sub can_be_inlined {
    !!1;
}

sub inline_check {
    my $self = shift;

    my $value = $self->value;

    my $code;
    if (defined $value) {
        $code = "(defined($_[0]) && $_[0] == $value)";
    }
    else {
        $code = "!defined($_[0])";
    }

    return "do { $Type::Tiny::SafePackage $code }"
        if $Type::Tiny::AvoidCallbacks; ## no critic (Variables::ProhibitPackageVars)
    return $code;
}

1;
__END__

=encoding utf-8

=head1 NAME

Type::Tiny::NumEqu - type constraint for single number equality with undefined

=head1 SYNOPSIS

    use Type::Tiny::NumEqu;

    my $Foo = Type::Tiny::NumEqu->new( value => 123 );
    $Foo->check(123); # true
    $Foo->check('123'); # true
    $Foo->check(124); # false

    my $Undef = Type::Tiny::NumEqu->new( value => undef );
    $Undef->check(undef); # true
    $Undef->check(123); # false

=head1 DESCRIPTION

This package inherits from Type::Tiny; see that for most documentation. Major differences are listed below:

=head2 Attributes

=over

=item C<value>

Allowable value number or undefined value. Non-number values (e.g. objects with
overloading) will be stringified in the constructor.

=back

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kfly@cpan.orgE<gt>

=cut

