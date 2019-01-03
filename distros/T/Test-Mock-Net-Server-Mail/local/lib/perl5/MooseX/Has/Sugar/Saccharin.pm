use 5.006;    # pragmas
use warnings;
use strict;

package MooseX::Has::Sugar::Saccharin;

our $VERSION = '1.000006';

# ABSTRACT: Experimental sweetness

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp ();
use Sub::Exporter::Progressive (
  -setup => {
    exports => [
      'ro',   'rw',      'required', 'lazy',      'lazy_build', 'coerce',  'weak_ref', 'auto_deref',
      'bare', 'default', 'init_arg', 'predicate', 'clearer',    'builder', 'trigger',
    ],
    groups => {
      default => ['-all'],
    },
  },
);
























sub bare($) {
  return ( 'is', 'bare', 'isa', shift, );
}













sub ro($) {
  return ( 'is', 'ro', 'isa', shift, );
}













sub rw($) {
  return ( 'is', 'rw', 'isa', shift, );
}
























sub required(@) {
  return ( 'required', 1, @_ );
}









sub lazy(@) {
  return ( 'lazy', 1, @_ );
}









sub lazy_build(@) {
  return ( 'lazy_build', 1, @_ );
}









sub weak_ref(@) {
  return ( 'weak_ref', 1, @_ );
}













sub coerce(@) {
  return ( 'coerce', 1, @_ );
}









sub auto_deref(@) {
  return ( 'auto_deref', 1, @_ );
}













sub builder($) {
  return ( 'builder', shift );
}









sub predicate($) {
  return ( 'predicate', shift );
}









sub clearer($) {
  return ( 'clearer', shift );
}









sub init_arg($) {
  return ( 'init_arg', shift );
}
















## no critic (ProhibitBuiltinHomonyms)
sub default(&) {
  my $code = shift;
  return (
    'default',
    sub {
      my $self = $_[0];
      local $_ = $self;
      return $code->();
    },
  );
}









sub trigger(&) {
  my $code = shift;
  return (
    'trigger',
    sub {
      my $self = $_[0];
      local $_ = $self;
      return $code->();
    },
  );
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Has::Sugar::Saccharin - Experimental sweetness

=head1 VERSION

version 1.000006

=head1 SYNOPSIS

This is a highly experimental sugaring module. No Guarantees of stability.

    use MooseX::Types::Moose qw( :all );
    has name   => rw Str, default { 1 };
    has suffix => required rw Str;
    has 'suffix', required rw Str;

Your choice.

=head1 EXPORT GROUPS

=head2 C<:default>

exports:

=over 4

L</ro>, L</rw>, L</required>, L</lazy>, L</lazy_build>, L</coerce>, L</weak_ref>, L</auto_deref>,
L</bare>, L</default>, L</init_arg>, L</predicate>, L</clearer>, L</builder>, L</trigger>

=back

=head1 EXPORTED FUNCTIONS

=head2 C<bare>

=head2 C<bare> C<$Type>

    bare Str

equivalent to this

    is => 'bare', isa => Str

=head2 C<ro>

=head2 C<ro> C<$Type>

    ro Str

equivalent to this

    is => 'ro', isa => Str,

=head2 C<rw>

=head2 C<rw> C<$Type>

    rw Str

equivalent to this

    is => 'rw', isa => Str

=head2 C<required>

=head2 C<required @rest>

this

    required rw Str

is equivalent to this

    required => 1, is => 'rw', isa => Str,

this

    rw Str, required

is equivalent to this

    is => 'rw', isa => Str , required => 1

=head2 C<lazy>

=head2 C<lazy @rest>

like C<< ( lazy => 1 , @rest ) >>

=head2 C<lazy_build>

=head2 C<lazy_build @rest>

like C<< ( lazy_build => 1, @rest ) >>

=head2 C<weak_ref>

=head2 C<weak_ref @rest>

like C<< ( weak_ref => 1, @rest ) >>

=head2 C<coerce>

=head2 C<coerce @rest>

like C<< ( coerce => 1, @rest ) >>

=head3 WARNING:

Conflicts with L<< C<MooseX::Types's> C<coerce> method|MooseX::Types/coerce >>

=head2 C<auto_deref>

=head2 C<auto_deref @rest>

like C<< ( auto_deref => 1, @rest ) >>

=head2 C<builder>

=head2 C<builder $buildername>

    required rw Str, builder '_build_foo'

is like

    builder => '_build_foo'

=head2 C<predicate>

=head2 C<predicate $predicatename>

see L</builder>

=head2 C<clearer>

=head2 C<clearer $clearername>

see L</builder>

=head2 C<init_arg>

=head2 C<init_arg $argname>

see L</builder>

=head2 C<default>

=head2 C<default { $code }>

Examples:

    default { 1 }
    default { { } }
    default { [ ] }
    default { $_->otherfield }

$_ is localized as the same value as $_[0] for convenience ( usually $self )

=head2 C<trigger>

=head2 C<trigger { $code }>

Works exactly like default.

=head1 CONFLICTS

=head2 MooseX::Has::Sugar

=head2 MooseX::Has::Sugar::Minimal

This module is not intended to be used in conjunction with
 L<::Sugar|MooseX::Has::Sugar> or L<::Sugar::Minimal|MooseX::Has::Sugar::Minimal>

We export many of the same symbols and its just not very sensible.

=head2 MooseX::Types

=head2 Moose::Util::TypeConstraints

due to exporting the L</coerce> symbol, using us in the same scope as a call to

    use MooseX::Types ....

or
    use Moose::Util::TypeConstraints

will result in a symbol collision.

We recommend using and creating proper type libraries instead, ( which will absolve you entirely of the need to use MooseX::Types and MooseX::Has::Sugar(::*)? in the same scope )

=head2 Perl 5.010 feature 'switch'

the keyword 'default' becomes part of Perl in both these cases:

    use 5.010;
    use feature qw( :switch );

As such, we can't have that keyword in that scenario.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
