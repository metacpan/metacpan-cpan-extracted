package Text::Nunjucks::Tests;
# ABSTRACT: 1:1 port of Nunjucks src/tests.js -- the built-in `is` tests

our $VERSION = '0.001';

use strict;
use warnings;
use builtin qw( true false );
use Text::Nunjucks::Lib;
use Text::Nunjucks::Runtime;

no warnings 'experimental::builtin';

# tests.js is a bag of `exports.<name> = fn` test functions. The port keeps
# upstream's order and names (snake_case: nullTest -> null_test, undefinedTest
# -> undefined_test); each test is a class method dispatched through $self,
# like Filters, so a test named like a Perl builtin (defined, ne, lt) never
# resolves to the builtin. `exports` builds the { name => coderef } bag, aliases
# included, that Environment.init registers with add_test. A test is called the
# way the compiler calls it, env.getTest(name)(value, args...) with no `this`
# (ADR 0009), and its result is compared === true (op_seq), so every test
# returns a JS boolean.
#
# JS operators (===, %, <, !, ...) go through Runtime, never Perl's native ones
# (ADR 0001 kinds, ADR 0006 null, ADR 0007 numbers); value kinds come from Lib.
# The native calls upstream makes on a value it never checked -- lower's
# value.toLowerCase(), iterable's value[Symbol.iterator] -- go through Runtime
# js_method_call / js_has_symbol_iterator, which throw V8's TypeError (ADR
# 0010). A JS Map, Set or generator has no Perl image (k44).

sub _lib     { 'Text::Nunjucks::Lib' }
sub _runtime { 'Text::Nunjucks::Runtime' }

#### callable

# Returns `true` if the object is a function, otherwise `false`.
sub callable {
  my ( $self, $value ) = @_;
  return $self->_lib->is_function($value) ? true : false;    # typeof value === 'function'
}

#### defined

# Returns `true` if the object is strictly not `undefined` (null is defined,
# ADR 0006).
sub defined {
  my ( $self, $value ) = @_;
  return defined($value) ? true : false;    # value !== undefined
}

#### divisibleby

# Returns `true` if the operand (one) is divisble by the test's argument (two).
sub divisibleby {
  my ( $self, $one, $two ) = @_;
  my $rt = $self->_runtime;
  return $rt->op_seq( $rt->op_mod( $one, $two ), 0 );
}

#### escaped

# Returns true if the string has been escaped (i.e., is a SafeString).
sub escaped {
  my ( $self, $value ) = @_;
  return $self->_runtime->_is_safe_string($value) ? true : false;    # value instanceof SafeString
}

#### equalto

# Returns `true` if the arguments are strictly equal.
sub equalto {
  my ( $self, $one, $two ) = @_;
  return $self->_runtime->op_seq( $one, $two );
}

#### even

# Returns `true` if the value is evenly divisible by 2.
sub even {
  my ( $self, $value ) = @_;
  my $rt = $self->_runtime;
  return $rt->op_seq( $rt->op_mod( $value, 2 ), 0 );
}

#### falsy

# Returns `true` if the value is falsy - '', 0, false, undefined, NaN or null
# (JS falsiness: '0', [] and {} are truthy).
sub falsy {
  my ( $self, $value ) = @_;
  return $self->_runtime->op_not($value);    # !value
}

#### ge

# Returns `true` if the operand (one) is greater or equal to the test's
# argument (two).
sub ge {
  my ( $self, $one, $two ) = @_;
  return $self->_runtime->op_ge( $one, $two );
}

#### greaterthan

# Returns `true` if the operand (one) is greater than the test's argument (two).
sub greaterthan {
  my ( $self, $one, $two ) = @_;
  return $self->_runtime->op_gt( $one, $two );
}

#### le

# Returns `true` if the operand (one) is less than or equal to the test's
# argument (two).
sub le {
  my ( $self, $one, $two ) = @_;
  return $self->_runtime->op_le( $one, $two );
}

#### lessthan

# Returns `true` if the operand (one) is less than the test's passed argument
# (two).
sub lessthan {
  my ( $self, $one, $two ) = @_;
  return $self->_runtime->op_lt( $one, $two );
}

#### lower

# Returns `true` if the string is lowercased. value.toLowerCase() on a value
# without it throws V8's TypeError (oracle: {{ 5 is lower }} -> "TypeError:
# value.toLowerCase is not a function", {{ null is lower }} -> "TypeError:
# Cannot read properties of null (reading 'toLowerCase')"); a SafeString's
# result is a primitive, never === the SafeString.
sub lower {
  my ( $self, $value ) = @_;
  my $rt = $self->_runtime;
  return $rt->op_seq( $rt->js_method_call( $value, 'value', 'toLowerCase' ), $value );
}

#### ne

# Returns `true` if the operand (one) is not strictly equal to the test's
# argument (two).
sub ne {
  my ( $self, $one, $two ) = @_;
  return $self->_runtime->op_sne( $one, $two );
}

#### nullTest

# Returns true if the value is strictly equal to `null` (the None sentinel,
# ADR 0006).
sub null_test {
  my ( $self, $value ) = @_;
  my $rt = $self->_runtime;
  return $rt->op_seq( $value, $rt->None );
}

#### number

# Returns true if value is a number (ADR 0001: created as a number; NaN and
# Infinity are numbers, a numeric string is not).
sub number {
  my ( $self, $value ) = @_;
  return ( defined($value) && builtin::created_as_number($value) ) ? true : false;    # typeof value === 'number'
}

#### odd

# Returns `true` if the value is *not* evenly divisible by 2.
sub odd {
  my ( $self, $value ) = @_;
  my $rt = $self->_runtime;
  return $rt->op_seq( $rt->op_mod( $value, 2 ), 1 );
}

#### string

# Returns `true` if the value is a string, `false` if not (ADR 0001; a
# SafeString is an object).
sub string {
  my ( $self, $value ) = @_;
  return $self->_lib->is_string($value) ? true : false;    # typeof value === 'string'
}

#### truthy

# Returns `true` if the value is not in the list of things considered falsy:
# '', null, undefined, 0, NaN and false.
sub truthy {
  my ( $self, $value ) = @_;
  my $rt = $self->_runtime;
  return $rt->op_not( $rt->op_not($value) );    # !!value
}

#### undefinedTest

# Returns `true` if the value is undefined.
sub undefined_test {
  my ( $self, $value ) = @_;
  return !defined($value) ? true : false;    # value === undefined
}

#### upper

# Returns `true` if the string is uppercased; value.toUpperCase() throws as
# lower's value.toLowerCase() does.
sub upper {
  my ( $self, $value ) = @_;
  my $rt = $self->_runtime;
  return $rt->op_seq( $rt->js_method_call( $value, 'value', 'toUpperCase' ), $value );
}

#### iterable

# Returns `true` if the value implements the `Symbol.iterator` method. Upstream
# falls back to Array.isArray(value) || typeof value === 'string' where the
# engine has no Symbol; every engine the port mirrors has it, so only the first
# branch is ported. undefined and null throw (oracle: {{ x is iterable }} ->
# "TypeError: undefined is not iterable (cannot read property
# Symbol(Symbol.iterator))"); a SafeString is iterable (String.prototype).
sub iterable {
  my ( $self, $value ) = @_;
  return $self->_runtime->js_has_symbol_iterator($value) ? true : false;    # !!value[Symbol.iterator]
}

#### mapping

# Returns `true` if the value is an object hash or an ES6 Map: typeof value ===
# 'object', so a regex, a SafeString, an engine-built object and any blessed
# object count; an array and a function do not. typeof 'object' is a reference
# that is not a coderef once undefined and null are out (ADR 0001: every JS
# primitive is a non-reference scalar, null the None sentinel of ADR 0006).
# The `!(value instanceof Set)` half has nothing to exclude: Perl has no Set
# (k44).
sub mapping {
  my ( $self, $value ) = @_;
  # only maps and object hashes
  my $bool = defined($value)                         # value !== undefined
    && !$self->_runtime->_is_none($value)           # value !== null
    && ref($value) && !$self->_lib->is_function($value)    # typeof value === 'object'
    && !$self->_lib->is_array($value);              # !Array.isArray(value)
  return $bool ? true : false;
}

#### exports -- { name => coderef }, in tests.js's order, aliases included

# tests.js's functions are module-level: every Environment registers the same
# ones (environment.js: lib._entries(tests).forEach(... this.addTest ...)). So
# the coderefs are built once per class and kept here; each call hands out a
# fresh hash of them, which Environment.init only reads.
my %exports_of;

sub exports {
  my ($self) = @_;
  return { %{ $exports_of{$self} } } if $exports_of{$self};
  my $exports = $exports_of{$self} = {
    callable    => sub { $self->callable(@_) },
    defined     => sub { $self->defined(@_) },
    divisibleby => sub { $self->divisibleby(@_) },
    escaped     => sub { $self->escaped(@_) },
    equalto     => sub { $self->equalto(@_) },
  };

  # Aliases
  $exports->{eq}     = $exports->{equalto};
  $exports->{sameas} = $exports->{equalto};

  $exports->{even}        = sub { $self->even(@_) };
  $exports->{falsy}       = sub { $self->falsy(@_) };
  $exports->{ge}          = sub { $self->ge(@_) };
  $exports->{greaterthan} = sub { $self->greaterthan(@_) };

  # alias
  $exports->{gt} = $exports->{greaterthan};

  $exports->{le}       = sub { $self->le(@_) };
  $exports->{lessthan} = sub { $self->lessthan(@_) };

  # alias
  $exports->{lt} = $exports->{lessthan};

  $exports->{lower}     = sub { $self->lower(@_) };
  $exports->{ne}        = sub { $self->ne(@_) };
  $exports->{null}      = sub { $self->null_test(@_) };
  $exports->{number}    = sub { $self->number(@_) };
  $exports->{odd}       = sub { $self->odd(@_) };
  $exports->{string}    = sub { $self->string(@_) };
  $exports->{truthy}    = sub { $self->truthy(@_) };
  $exports->{undefined} = sub { $self->undefined_test(@_) };
  $exports->{upper}     = sub { $self->upper(@_) };
  $exports->{iterable}  = sub { $self->iterable(@_) };
  $exports->{mapping}   = sub { $self->mapping(@_) };

  return {%$exports};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Tests - 1:1 port of Nunjucks src/tests.js -- the built-in `is` tests

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A 1:1 port of Nunjucks C<src/tests.js>: the built-in C<is> tests. C<exports> returns
the name to code reference hash an Environment registers when it is constructed.
The tests are described in the Nunjucks template documentation,
L<https://mozilla.github.io/nunjucks/templating.html#builtin-tests>. To add or replace
a test use C<add_test> of L<Text::Nunjucks::Environment>.

Engine-internal: used by L<Text::Nunjucks::Environment> and the code the compiler emits, and
not an interface for applications.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-text-nunjucks/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
