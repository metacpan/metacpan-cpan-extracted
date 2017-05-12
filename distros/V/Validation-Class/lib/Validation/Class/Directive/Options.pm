# ABSTRACT: Options Directive for Validation Class Field Definitions

package Validation::Class::Directive::Options;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must be either %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{options} && defined $param) {

        my $options = $field->{options};

        if ( $field->{required} || $param ) {

            my (@options) = isa_arrayref($options) ?
                @{$options} : split /(?:\s{1,})?[,\-]{1,}(?:\s{1,})?/, $options
            ;

            foreach my $option (@options) {
                if ($option =~ /^([^\|]+)\|(.*)/) {
                    $option = $0;
                }
                elsif (isa_arrayref($option)) {
                    $option = $option->[0];
                }
            }

            unless (grep { $param eq $_ } @options) {

                if (my @o = @options) {

                    my$list=(join(' or ',join(', ',@o[0..$#o-1])||(),$o[-1]));

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

Validation::Class::Directive::Options - Options Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            user_role => {
                options => 'Client'
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

Validation::Class::Directive::Options is a core validation class field directive
that holds an enumerated list of values to be validated against the associated
parameters.

=over 8

=item * alternative argument: an-array-of-user-defined-options

This directive can be passed a single value or an array of values:

    fields => {
        user_role => {
            options => ['Client', 'Employee', 'Administrator']
        }
    }

    # the following examples are useful for plugins (and other code)
    # that may want to otherwise identify option values

    fields => {
        user_role => {
            options => [
                '1|Client',
                '2|Employee',
                '3|Administrator'
            ]
        }
    }

    # please note:
    # declaring options as "keyed-options" will cause the validation of
    # the option's key and NOT the option's value

    fields => {
        user_role => {
            options => [
                [ 1 => 'Client' ],
                [ 2 => 'Employee' ],
                [ 3 => 'Administrator' ]
            ]
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
