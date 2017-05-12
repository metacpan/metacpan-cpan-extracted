# ABSTRACT: Errors Directive for Validation Class Field Definitions

package Validation::Class::Directive::Errors;

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

Validation::Class::Directive::Errors - Errors Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 DESCRIPTION

Validation::Class::Directive::Errors is a core validation class field directive
that holds error message registered at the field-level for the associated field.
This directive is used internally.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
