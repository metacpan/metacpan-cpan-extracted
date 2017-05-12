# ABSTRACT: Toggle Directive for Validation Class Field Definitions

package Validation::Class::Directive::Toggle;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{toggle}) {

        my $stash = $proto->stash->{'directive.toggle'} ||= {};

        # to be restored after validation

        $stash->{$field->{name}}->{'required'} =
            defined $field->{required} ? $field->{required} == 0 ? 0 : 1 : 0;

        $field->{required} = 1 if ($field->{toggle} =~ /^(\+|1)$/);
        $field->{required} = 0 if ($field->{toggle} =~ /^(\-|0)$/);

    }

    return $self;

}

sub after_validation {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{toggle}) {

        my $stash = $proto->stash->{'directive.toggle'} ||= {};

        if (defined $stash->{$field->{name}}->{'required'}) {

            # restore field state from stash after validation

            $field->{required} = $stash->{$field->{name}}->{'required'};

            delete $stash->{$field->{name}};

        }

    }

    delete $field->{toggle} if exists $field->{toggle};

    return $self;

}

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # on normalize, always remove the toggle directive

    delete $field->{toggle} if exists $field->{toggle};

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Toggle - Toggle Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 DESCRIPTION

Validation::Class::Directive::Toggle is a core validation class field directive
that is used internally to handle validation of per-validation-event
requirements.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
