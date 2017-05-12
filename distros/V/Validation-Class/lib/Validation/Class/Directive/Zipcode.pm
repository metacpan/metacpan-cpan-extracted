# ABSTRACT: Zipcode Directive for Validation Class Field Definitions

package Validation::Class::Directive::Zipcode;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not a valid postal code';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{zipcode} && defined $param) {

        if ($field->{required} || $param) {

            my $zcre = qr/\A\b[0-9]{5}(?:-[0-9]{4})?\b\z/i;
            $self->error($proto, $field) unless $param =~ $zcre;

        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Zipcode - Zipcode Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            address_zipcode => {
                zipcode => 1
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

Validation::Class::Directive::Zipcode is a core validation class field directive
that handles postal-code validation for areas in the USA and North America.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
