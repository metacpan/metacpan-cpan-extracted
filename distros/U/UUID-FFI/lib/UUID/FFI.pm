package UUID::FFI;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus 1.00;
use FFI::Platypus::Memory ();
use FFI::CheckLib ();
use Carp qw( croak );
use overload '<=>' => sub { $_[0]->compare($_[1]) },
             '""'  => sub { shift->as_hex         },
             bool => sub { 1 }, fallback => 1;

# TODO: as_bin or similar

# ABSTRACT: Universally Unique Identifiers FFI style
our $VERSION = '0.10'; # VERSION


my $ffi = FFI::Platypus->new( api => 1 );

$ffi->lib(sub {
  my @lib = eval {
    require Alien::libuuid;
    Alien::libuuid->VERSION('0.05');
    Alien::libuuid->dynamic_libs;
  };
  return @lib if @lib;
  @lib = FFI::CheckLib::find_lib(
    lib => 'uuid',
    symbol => [
      'uuid_generate_random',
      'uuid_generate_time',
      'uuid_unparse',
      'uuid_parse',
      'uuid_copy',
      'uuid_clear',
      'uuid_type',
      'uuid_variant',
      'uuid_time',
      'uuid_is_null',
      'uuid_compare',
    ]
  );
  die "Unable to find system libuuid with required symbols.  Try installing or upgrading Alien::libuuid"
    unless @lib;
  return @lib;
});

$ffi->attach( [uuid_generate_random => '_generate_random'] => ['opaque']           => 'void'   => '$'  );
$ffi->attach( [uuid_generate_time   => '_generate_time']   => ['opaque']           => 'void'   => '$'  );
$ffi->attach( [uuid_unparse         => '_unparse']         => ['opaque', 'opaque'] => 'void'   => '$$' );
$ffi->attach( [uuid_parse           => '_parse']           => ['string', 'opaque'] => 'int'    => '$$' );
$ffi->attach( [uuid_copy            => '_copy']            => ['opaque', 'opaque'] => 'void'   => '$$' );
$ffi->attach( [uuid_clear           => '_clear']           => ['opaque']           => 'void'   => '$'  );
$ffi->attach( [uuid_type            => '_type']            => ['opaque']           => 'int'    => '$'  );
$ffi->attach( [uuid_variant         => '_variant']         => ['opaque']           => 'int'    => '$'  );
$ffi->attach( [uuid_time            => '_time']            => ['opaque', 'opaque'] => 'time_t' => '$$' );
$ffi->attach( [uuid_is_null         => '_is_null']         => ['opaque']           => 'int'    => '$'  );
$ffi->attach( [uuid_compare         => '_compare']         => ['opaque', 'opaque'] => 'int'    => '$$' );


sub new
{
  my($class, $hex) = @_;
  croak "usage: UUID::FFI->new($hex)" unless $hex;
  my $self = bless \FFI::Platypus::Memory::malloc(16), $class;
  my $r = _parse($hex, $$self);
  croak "$hex is not a valid hex UUID" if $r != 0;
  $self;
}


sub new_random
{
  my($class) = @_;
  my $self = bless \FFI::Platypus::Memory::malloc(16), $class;
  _generate_random->($$self);
  $self;
}


sub new_time
{
  my($class) = @_;
  my $self = bless \FFI::Platypus::Memory::malloc(16), $class;
  _generate_time($$self);
  $self;
}


sub new_null
{
  my($class) = @_;
  my $self = bless \FFI::Platypus::Memory::malloc(16), $class;
  _clear($$self);
  $self;
}


sub is_null { _is_null(${$_[0]}) }


sub clone
{
  my($self) = @_;
  my $other = bless \FFI::Platypus::Memory::malloc(16), ref $self;
  _copy($$other, $$self);
  $other;
}


sub as_hex
{
  my($self) = @_;
  my $data = "x" x 36;
  my $ptr = unpack 'L!', pack 'P', $data;
  _unparse($$self, $ptr);
  $data;
}


sub compare { _compare( ${$_[0]}, ${$_[1]} ) }

my %type_map = (
  1 => 'time',
  4 => 'random',
);


sub type
{
  my($self) = @_;
  my $r = _type($$self);
  $type_map{$r} || croak "illegal type: $r";
}

my @variant = qw( ncs dce microsoft other );


sub variant
{
  my($self) = @_;
  my $r = _variant($$self);
  $variant[$r] || croak "illegal varient: $r";
}


sub time
{
  my($self) = @_;
  _time($$self, undef);
}

sub DESTROY
{
  my($self) = @_;
  FFI::Platypus::Memory::free($$self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

UUID::FFI - Universally Unique Identifiers FFI style

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 my $uuid = UUID::FFI->new_random;
 print $uuid->as_hex, "\n";

=head1 DESCRIPTION

This module provides an FFI interface to C<libuuid>.
C<libuuid> library is used to generate unique identifiers
for objects that may be accessible beyond the local system

=head1 CONSTRUCTORS

=head2 new

 my $uuid = UUID::FFI->new($hex);

Create a new UUID object from the hex representation C<$hex>.

=head2 new_random

 my $uuid = UUID::FFI->new_random;

Create a new UUID object with a randomly generated value.

=head2 new_time

 my $uuid = UUID::FFI->new_time;

Create a new UUID object generated using the time and mac address.
This can leak information about when and where the UUID was generated.

=head2 new_null

 my $uuid = UUID::FFI->new_null;

Create a new UUID C<NULL UUID>  object (all zeros).

=head1 METHODS

=head2 is_null

 my $bool = $uuid->is_null;

Returns true if the UUID is C<NULL UUID>.

=head2 clone

 my $uuid2 = $uuid->clone;

Create a new UUID object with the identical value to the original.

=head2 as_hex

 my $hex = $uuid->as_hex;
 my $hex = "$uuid";

Returns the hex representation of the UUID.  The stringification of
L<UUID::FFI> uses this function, so you can also use it in a double quoted string.

=head2 compare

 my $cmp = $uuid1->compare($uuid2);
 my $cmp = $uuid1 <=> $uuid2;
 my @sorted_uuids = sort { $a->compare($b) } @uuids;
 my @sorted_uuids = sort { $a <=> $b } @uuids;

Returns an integer less than, equal to or greater than zero
if C<$uuid1> is found, respectively, to be lexicographically
less than, equal, or greater that C<$uuid2>.  The C<E<lt>=E<gt>>
is also overloaded so you can use that too.

=head2 type

 my $type = $uuid->type;

Returns the type of UUID, either C<time> or C<random>,
if it can be identified.

=head2 variant

 my $variant = $uuid->variant

Returns the variant of the UUID, either C<ncs>, C<dce>, C<microsoft> or C<other>.

=head2 time

 my $time = $uuid->time;

Returns the time the UUID was generated.  The value returned is in seconds
since the UNIX epoch, so is compatible with perl builtins like L<time|perlfunc#time> and
L<localtime|perlfunc#localtime>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
