# ABSTRACT: Time Directive for Validation Class Field Definitions

package Validation::Class::Directive::Time;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s requires a valid time';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{time} && defined $param) {

        if ($field->{required} || $param) {

            # determines if the param is a valid time
            # validates time as 24hr (HH:MM) or am/pm ([H]H:MM[a|p]m)
            # does not validate seconds

            my $tre = qr%^((0?[1-9]|1[012])(:[0-5]\d){0,2} ?([AP]M|[ap]m))$|^([01]\d|2[0-3])(:[0-5]\d){0,2}$%;

            $self->error($proto, $field) unless $param =~ $tre;

        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Time - Time Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            creation_time => {
                time => 1
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

Validation::Class::Directive::Time is a core validation class field directive
that handles validation for standard time formats. This directive respects the
following time formats, 24hr (HH:MM) or am/pm ([H]H:MM[a|p]m) and does not
validate seconds.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
