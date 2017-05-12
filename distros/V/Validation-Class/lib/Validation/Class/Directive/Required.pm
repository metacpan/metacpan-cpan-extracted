# ABSTRACT: Required Directive for Validation Class Field Definitions

package Validation::Class::Directive::Required;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'        => 1;
has 'field'        => 1;
has 'multi'        => 0;
has 'message'      => '%s is required';
has 'dependencies' => sub {{
    normalization => [],
    validation    => ['alias', 'toggle']
}};

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{required}) {

        if ($field->{required} && (! defined $param || $param eq '')) {

            $self->error($proto, $field);
            $proto->stash->{'validation.bypass_event'}++
                unless $proto->ignore_intervention;

        }

    }

    return $self;

}

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # by default, field validation is optional

    $field->{required} = 0 unless defined $field->{required};

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Required - Required Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            search_query => {
                required => 1
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

Validation::Class::Directive::Required is a core validation class field
directive that handles validation of supply and demand.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
