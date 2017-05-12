# ABSTRACT: Readonly Directive for Validation Class Field Definitions

package Validation::Class::Directive::Readonly;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

sub normalize {

    my ($self, $proto, $field) = @_;

    # respect readonly fields

    if (defined $field->{readonly}) {

        my $name = $field->name;

        # probably shouldn't be deleting the submitted parameters !!!
        delete $proto->params->{$name} if exists $proto->params->{$name};

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Readonly - Readonly Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            task_completed => {
                readonly => 1
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

Validation::Class::Directive::Readonly is a core validation class field
directive that determines whether the associated parameters should be ignored.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
