# ABSTRACT: DependsOn Directive for Validation Class Field Definitions

package Validation::Class::Directive::DependsOn;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 1;
has 'message' => '%s requires %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{depends_on} && defined $param) {

        my $specification = $field->{depends_on};

        if ($field->{required} || $param) {

            my $dependents = isa_arrayref($specification) ?
                $specification : [$specification]
            ;

            if (@{$dependents}) {

                my @required_fields = ();

                foreach my $dependent (@{$dependents}) {

                    my $field = $proto->fields->get($dependent);

                    push @required_fields, $field->label || $field->name
                        unless $proto->params->has($dependent)
                    ;

                }

                if (my @r = @required_fields) {

                    my$list=(join(' and ',join(', ',@r[0..$#r-1])||(),$r[-1]));

                    $self->error(@_, $list);

                }

            }

        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::DependsOn - DependsOn Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            password_confirmation  => {
                depends_on => 'password'
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

Validation::Class::Directive::DependsOn is a core validation class field
directive that validates the existence of dependent parameters.

=over 8

=item * alternative argument: an-array-of-parameter-names

This directive can be passed a single value or an array of values:

    fields => {
        password2_confirmation => {
            depends_on => ['password', 'password2']
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
