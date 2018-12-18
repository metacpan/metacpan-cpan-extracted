# ABSTRACT: Type::Tiny Method/Function Signatures
package Type::Tiny::Signatures;

use 5.14.0;

use strict;
use warnings;

our $VERSION = '0.71.0'; # VERSION

require Function::Parameters;
require Type::Registry;
require Type::Tiny;

our @DEFAULTS = 'Types::Standard';

sub import {
  my $class = shift;
  my $reify = sub {
    Type::Registry->for_class($class)->lookup($_[0])
  };

  Function::Parameters->import($class->settings($reify));
  Type::Registry->for_class($class)->add_types($_) for grep !/^:/, @DEFAULTS, @_;

  return;
}

sub settings {
  my ($class, $reifier) = @_;

  my $func_settings = $class->settings_for_func($reifier);
  my $meth_settings = $class->settings_for_meth($reifier);

  return { fun => $func_settings, method => $meth_settings };
}

sub settings_for_func {
  my ($class, $reifier) = @_;

  return {
    check_argument_count => 0,
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'function',
    invocant             => 0,
    name                 => 'optional',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    types                => 1,
  };
}

sub settings_for_meth {
  my ($class, $reifier) = @_;

  return {
    attributes           => ':method',
    check_argument_count => 0,
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    invocant             => 1,
    name                 => 'optional',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    shift                => '$self',
    types                => 1,
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Type::Tiny::Signatures - Type::Tiny Method/Function Signatures

=head1 VERSION

version 0.71.0

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

Al Newkirk <al@iamalnewkirk.com>

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
