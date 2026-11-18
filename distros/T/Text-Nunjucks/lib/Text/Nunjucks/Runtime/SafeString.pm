package Text::Nunjucks::Runtime::SafeString;
# ABSTRACT: A string marked as safe from autoescaping (runtime.js SafeString)

our $VERSION = '0.001';

use strict;
use warnings;
use overload
  '""'   => sub { $_[0]->{val} },
  'bool' => sub { 1 },
  fallback => 1;
use Text::Nunjucks::Lib;

# upstream: function SafeString in src/runtime.js (a String subclass).
#
# JS: `function SafeString(val){ if (typeof val!=='string') return val; ... }`
# and prototype valueOf/toString both return this.val. Marks a string as not
# to be autoescaped. Overloads stringification to val so the compiler's output
# concatenation coerces it exactly as JS's `+ ''` does.

sub new {
  my ( $class, $val ) = @_;
  # if (typeof val !== 'string') return val;  -- non-strings pass through
  return $val unless Text::Nunjucks::Lib->is_string($val);
  # this.length = val.length -- in UTF-16 code units (ADR 0012)
  return bless { val => $val, length => Text::Nunjucks::Lib->js_string_length($val) }, $class;
}

sub val       { $_[0]->{val} }
sub length    { $_[0]->{length} }
sub value_of  { $_[0]->{val} }    # SafeString.prototype.valueOf
sub to_string { $_[0]->{val} }    # SafeString.prototype.toString

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Runtime::SafeString - A string marked as safe from autoescaping (runtime.js SafeString)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A string the engine outputs without autoescaping it, as the C<safe> filter
returns it for a string. It stringifies to its value.

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
