# ABSTRACT: Matches Directive for Validation Class Field Definitions

package Validation::Class::Directive::Matches;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 1;
has 'message' => '%s does not match %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{matches} && defined $param) {

        my $specification = $field->{matches};

        if ($field->{required} || $param) {

            my $dependents = isa_arrayref($specification) ?
                $specification : [$specification]
            ;

            if (@{$dependents}) {

                my @required_fields = ();

                foreach my $dependent (@{$dependents}) {

                    $param ||= '';

                    my $field  = $proto->fields->get($dependent);
                    my $param2 = $proto->params->get($dependent) || '';

                    push @required_fields, $field->label || $field->name
                        unless $param eq $param2
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

Validation::Class::Directive::Matches - Matches Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            password => {
                matches => 'password2'
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

Validation::Class::Directive::Matches is a core validation class field directive
that validates whether the value of the dependent parameters matches that of
the associated field.

=over 8

=item * alternative argument: an-array-of-parameter-names

This directive can be passed a single value or an array of values:

    fields => {
        password => {
            matches => ['password2', 'password3']
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
