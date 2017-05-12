# ABSTRACT: Validation Directive for Validation Class Field Definitions

package Validation::Class::Directive::Validation;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'        => 0;
has 'field'        => 1;
has 'multi'        => 0;
has 'message'      => '%s could not be validated';
# ensure most core directives execute before this one
has 'dependencies' => sub {{
    normalization => [],
    validation    => [qw(
        alias
        between
        default
        depends_on
        error
        errors
        filtering
        filters
        label
        length
        matches
        max_alpha
        max_digits
        max_length
        max_sum
        min_alpha
        min_digits
        min_length
        min_sum
        mixin
        mixin_field
        multiples
        name
        options
        pattern
        readonly
        required
        toggle
        value
    )]
}};

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{validation} && defined $param) {

        my $context = $proto->stash->{'validation.context'};

        my $count  = ($proto->errors->count+$field->errors->count);
        my $failed = !$field->validation->($context,$field,$proto->params)?1:0;
        my $errors = ($proto->errors->count+$field->errors->count)>$count ?1:0;

        # error handling; did the validation routine pass or fail?

        # validation passed with no errors
        if (!$failed && !$errors) {
            # noop
        }

        # validation failed with no errors
        elsif ($failed && !$errors) {
            $self->error(@_);
        }

        # validation passed with errors
        elsif (!$failed && $errors) {
            # noop -- but acknowledge errors have been set
        }

        # validation failed with errors
        elsif ($failed && $errors) {
            # assume errors have been set from inside the validation routine
        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Validation - Validation Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            example_data => {
                validation => sub {

                    my ($self, $proto, $field, $params) = @_;
                    # user-defined validation should return true/false

                }
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

Validation::Class::Directive::Validation is a core validation class field
directive that is used to execute user-defined validation routines. This
directive always takes a sub-routine and should return true or false.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
