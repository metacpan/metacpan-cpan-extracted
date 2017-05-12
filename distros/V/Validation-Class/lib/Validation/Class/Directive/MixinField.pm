# ABSTRACT: MixinField Directive for Validation Class Field Definitions

package Validation::Class::Directive::MixinField;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::MixinField - MixinField Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            first_name => {
                required => 1,
                filters  => ['trim', 'strip']
            },
            last_name => {
                mixin_field => 'first_name'
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

Validation::Class::Directive::MixinField is a core validation class field
directive that determines what fields will be used as templates and merged with
the associated field.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
