# ABSTRACT: Messages Directive for Validation Class Field Definitions

package Validation::Class::Directive::Messages;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 0;

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Messages - Messages Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            username => {
                required   => 1,
                min_length => 5,
                messages => {
                    required   => '%s is mandatory',
                    min_length => '%s is not the correct length'
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

Validation::Class::Directive::Messages is a core validation class field
directive that holds error message which will supersede the default error
messages of the associated directives.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
