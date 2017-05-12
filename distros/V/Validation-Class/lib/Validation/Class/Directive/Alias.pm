# ABSTRACT: Alias Directive for Validation Class Field Definitions

package Validation::Class::Directive::Alias;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'        => 0;
has 'field'        => 1;
has 'multi'        => 0;
has 'dependencies' => sub {{
    normalization => ['name'],
    validation    => ['name']
}};

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # create a map from aliases if applicable

    $self->execute_alias_mapping($proto, $field, $param);

    return $self;

}

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    # create a map from aliases if applicable

    $self->execute_alias_mapping($proto, $field, $param);

    return $self;

}

sub execute_alias_mapping {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{alias}) {

        my $name = $field->{name};

        my $aliases = isa_arrayref($field->{alias}) ?
            $field->{alias} : [$field->{alias}]
        ;

        foreach my $alias (@{$aliases}) {

            if ($proto->params->has($alias)) {

                # rename the submitted parameter alias with the field name
                $proto->params->add($name => $proto->params->delete($alias));

                push @{$proto->stash->{'validation.fields'}}, $name unless
                    grep { $name eq $_} @{$proto->stash->{'validation.fields'}}
                ;

            }

        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Alias - Alias Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            login  => {
                alias => 'username'
            }
        }
    );

    # set parameters to be validated
    $rules->params->add($parameters);

    # validate
    unless ($rules->validate) {
        # handle the failures
    }

=head1 DESCRIPTION

Validation::Class::Directive::Alias is a core validation class field directive
that provides the ability to map arbitrary parameter names with a field's
parameter value.

=over 8

=item * alternative argument: an-array-of-aliases

This directive can be passed a single value or an array of values:

    fields => {
        login  => {
            alias => ['username', 'email_address']
        }
    }

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
