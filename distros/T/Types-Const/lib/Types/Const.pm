package Types::Const;

use v5.8;

use strict;
use warnings;

# ABSTRACT: Types that coerce references to read-only

use Type::Library
   -base,
   -declare => qw/ ConstArrayRef /;

use Const::Fast ();
use Type::Tiny;
use Type::Utils -all;
use Types::Standard -types;

our $VERSION = 'v0.1.0';


declare "ConstArrayRef",
  as ArrayRef,
  where   { Internals::SvREADONLY(@$_) },
  message {
    return ArrayRef->get_message($_) unless ArrayRef->check($_);
    return "$_ is not readonly";
  };

coerce "ConstArrayRef",
  from ArrayRef,
  via { Const::Fast::_make_readonly( $_ => 0 ); return $_; };


declare "ConstHashRef",
  as HashRef,
  where   { Internals::SvREADONLY(%$_) },
  message {
    return HashRef->get_message($_) unless HashRef->check($_);
    return "$_ is not readonly";
  };

coerce "ConstHashRef",
  from HashRef,
  via { Const::Fast::_make_readonly( $_ => 0 ); return $_; };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::Const - Types that coerce references to read-only

=head1 VERSION

version v0.1.0

=head1 SYNOPSIS

  use Types::Const -types;
  use Types::Standard -types;

  ...

  has bar => (
    is      => 'ro',
    isa     => ConstArrayRef,
    coerce  => 1,
  );

=head1 DESCRIPTION

The type library provides types that allow read-only attributes to be
read-only.

=head1 TYPES

=head2 C<ConstArrayRef>

A read-only array reference.

=head2 C<ConstHashRef>

A read-only hash reference.

=head1 KNOWN ISSUES

Parameterized types, e.g. C<ConstArrayRef[Int]> are not yet supported.

=head1 SEE ALSO

L<Const::Fast>

L<Type::Tiny>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Types-Const>
and may be cloned from L<git://github.com/robrwo/Types-Const.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Types-Const/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
