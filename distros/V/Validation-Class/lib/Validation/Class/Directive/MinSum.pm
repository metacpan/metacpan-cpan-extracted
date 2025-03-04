# ABSTRACT: MinSum Directive for Validation Class Field Definitions

package Validation::Class::Directive::MinSum;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900059'; # VERSION


has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must be greater than %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{min_sum} && defined $param) {

        my $min_sum = $field->{min_sum};

        if ( $field->{required} || $param ) {

            if (int($param) < int($min_sum)) {

                $self->error(@_, $min_sum);

            }

        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::MinSum - MinSum Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900059

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            invoice_total => {
                min_sum => 1
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

Validation::Class::Directive::MinSum is a core validation class field directive
that validates the numeric value of the associated parameters.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
