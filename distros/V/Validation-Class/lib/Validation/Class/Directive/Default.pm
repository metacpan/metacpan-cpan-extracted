# ABSTRACT: Default Directive for Validation Class Field Definitions

package Validation::Class::Directive::Default;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'        => 1;
has 'field'        => 1;
has 'multi'        => 1;
has 'dependencies' => sub {{
    normalization  => ['filters', 'readonly'],
    # note: default-values are only handled during normalization now
    # validation   => ['multiples', 'value']
}};

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # override parameter value if default exists

    if (defined $field->{default} && ! defined $param) {

        my @defaults = isa_arrayref($field->{default}) ?
            @{$field->{default}} : ($field->{default})
        ;

        my $context = $proto->stash->{'normalization.context'};
        my $name    = $field->name;

        foreach my $default (@defaults) {
            $default = $default->($context, $proto) if isa_coderef($default);
        }

        $proto->params->add($name, @defaults == 1 ? $defaults[0] : [@defaults]);

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Default - Default Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            access_code  => {
                default => 'demo123'
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

Validation::Class::Directive::Default is a core validation class field
directive that holds the value which should be used if no parameter is
supplied.

=over 8

=item * alternative argument: a-coderef-returning-a-default-value

This directive can be passed a single value or a coderef which should return
the value to be used as the default value:

    fields => {
        access_code => {
            default => sub {
                my $self = shift; # this coderef will receive a context object
                return join '::', lc __PACKAGE__, time();
            }
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
