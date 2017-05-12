# ABSTRACT: Multiples Directive for Validation Class Field Definitions

package Validation::Class::Directive::Multiples;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'        => 0;
has 'field'        => 1;
has 'multi'        => 0;
has 'message'      => '%s does not support multiple values';
# ensure most core directives execute before this one
has 'dependencies' => sub {{
    normalization => [],
    validation    => [qw(
        alias
        between
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
        name
        options
        pattern
        readonly
        required
        toggle
    )]
}};

sub after_validation {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{multiples} && defined $param) {

        $self->after_validation_delete_clones($proto, $field, $param);

    }

    return $self;

}

sub after_validation_delete_clones {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    my $name = $field->name;

    # this will add additional processing overhead which we hate, but is how we
    # will currently prevent the reaping of strangely named fields that appear
    # to be clones/clonable but are not in-fact ... so we'll check if the field
    # is in the clones array
    return unless grep { defined $_ and $name eq $_ }
        @{$proto->stash->{'directive.validation.clones'}}
    ;

    my ($key, $index) = $name =~ /^(.*)\:(\d+)$/;

    if ($key && defined $index) {

        my $value = $proto->params->delete($name);

        $proto->params->{$key} ||= [];

        $proto->params->{$key}->[$index] = $value;

        # inherit errors from clone

        if ($proto->fields->has($key) && $proto->fields->has($name)) {

            $proto->fields->get($key)->errors->add(

                $proto->fields->get($name)->errors->list

            );

        }

        # remove clone permenantly

        $proto->fields->delete($name);

        delete $proto->stash->{'directive.validation.clones'}->[$index];

    }

    return $self;

}

sub before_validation {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{multiples} && defined $param) {

        $self->before_validation_create_clones($proto, $field, $param);

    }

    return $self;

}

sub before_validation_create_clones {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    # clone fields to handle parameters with multi-values

    if (isa_arrayref($param)) {

        # is cloning allowed? .. in the U.S it is currently illegal :}

        return $self->error(@_) if ! $field->{multiples};

        # clone deterministically

        my $name = $field->name;

        for (my $i=0; $i < @{$param}; $i++) {

            my $clone = "$name:$i";

            $proto->params->add($clone => $param->[$i]);

            my $label   = ($field->label || $name);
            my $options = {label => "$label #".($i+1), multiples => 0};

            $proto->clone_field($name, $clone => $options);

            # add clones to field list to be validated
            push @{$proto->stash->{'validation.fields'}}, $clone
                if grep { $_ eq $name } @{$proto->stash->{'validation.fields'}}
            ;

            # record clones (to be reaped later)
            push @{$proto->stash->{'directive.validation.clones'}}, $clone;

        }

        $proto->params->delete($name);

        # remove the field the clones are based on from the fields list
        @{$proto->stash->{'validation.fields'}} =
            grep { $_ ne $name } @{$proto->stash->{'validation.fields'}}
            if @{$proto->stash->{'validation.fields'}}
        ;

    }

    return $self;

}

sub normalize {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    # set a default value for the multiples directives
    # ... the default policy is deny,allow

    $field->{multiples} = 0 if ! defined $field->{multiples};

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Multiples - Multiples Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            user_options => {
                multiples => 1
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

Validation::Class::Directive::Multiples is a core validation class field
directive that validates whether the associated parameters may contain a
multi-value (an array of strings).

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
