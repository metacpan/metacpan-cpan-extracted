# ABSTRACT: Method/Function Signatures w/Type::Tiny Constraints
package Type::Tiny::Signatures;

use 5.14.0;

use strict;
use warnings;

require Function::Parameters;
require Type::Registry;
require Type::Tiny;

our $CALLER   = caller;
our @DEFAULTS = 'Types::Standard';
our $SETTINGS = {};

$SETTINGS->{fun} = {
  check_argument_count => 0,
  check_argument_types => 1,
  default_arguments    => 1,
  defaults             => 'function',
  invocant             => 0,
  name                 => 'optional',
  named_parameters     => 1,
  reify_type           => sub { Type::Registry->for_class($CALLER)->lookup($_[0]) },
  runtime              => 1,
  types                => 1,
};

$SETTINGS->{method} = {
  attributes           => ':method',
  check_argument_count => 0,
  check_argument_types => 1,
  default_arguments    => 1,
  defaults             => 'method',
  invocant             => 1,
  name                 => 'optional',
  named_parameters     => 1,
  reify_type           => sub { Type::Registry->for_class($CALLER)->lookup($_[0]) },
  runtime              => 1,
  shift                => '$self',
  types                => 1,
};

our $VERSION = '0.07'; # VERSION

sub import {
  shift;

  Type::Registry->for_class($CALLER)->add_types($_) for @DEFAULTS, grep !/^:/, @_;
  Function::Parameters->import($SETTINGS);

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Type::Tiny::Signatures - Method/Function Signatures w/Type::Tiny Constraints

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use Type::Tiny;
  use Type::Tiny::Signatures;

  method hello (Str $greeting, Str $fullname) {
    print "$greeting, $fullname\n";
  }

=head1 DESCRIPTION

This module uses L<Function::Parameters> to extend Perl with keywords that
let you define methods and functions with parameter lists which can be validated
using L<Type::Tiny> type constraints. The type constraints can be provided by
the Type::Tiny standard library, L<Types::Standard>, or any supported
user-defined type library which can be a L<Moose>, L<MooseX::Type>,
L<MouseX::Type>, or L<Type::Library> library.

  use Type::Tiny;
  use Type::Tiny::Signatures 'MyApp::Types';

  method identify (Str $name, SSN $number) {
    print "identifying $name using SSN $number\n";
  }

The method and function signatures can be configured to validate user-defined
type constraints by passing the user-defined type library package name as an
argument to the Type::Tiny::Signatures usage declaration. The default behavior
configures the Function::Parameters pragma using options that mimick the
previously default lax-mode, i.e. strict-mode disabled.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 CONTRIBUTOR

=for stopwords Al Newkirk

Al Newkirk <al@iamalnewkirk.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
