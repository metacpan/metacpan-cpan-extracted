package Tie::Hash::Interpolate;

use 5.006;
use strict;
use warnings;

use Carp;
use Scalar::Util qw/ looks_like_number blessed /;

use constant EX_LINEAR   => 'linear';
use constant EX_CONSTANT => 'constant';
use constant EX_FATAL    => 'fatal';
use constant EX_UNDEF    => 'undef';

use constant ONE_KEY_FATAL    => 'fatal';
use constant ONE_KEY_CONSTANT => 'constant';
use constant ONE_KEY_UNDEF    => 'undef';

our $VERSION = '0.07';

sub new
   {
   my ($class, %opts) = @_;
   my $tied = {};
   tie %{$tied}, $class, %opts;
   return $tied;
   }

sub TIEHASH
   {
   my ($class, %opts) = (shift, extrapolate => EX_LINEAR, one_key => ONE_KEY_FATAL, @_);
   croak "invalid value for 'extrapolate' option ($opts{'extrapolate'})"
      unless grep $_ eq $opts{'extrapolate'}, EX_LINEAR, EX_UNDEF, EX_FATAL, EX_CONSTANT;
   croak "invalid value for 'one_key' option ($opts{'one_key'})"
      unless grep $_ eq $opts{'one_key'}, ONE_KEY_UNDEF, ONE_KEY_FATAL, ONE_KEY_CONSTANT;
   my $self = { _DATA => {}, _KEYS => [], _SORT => 1, _OPTS => \%opts };
   bless $self, $class;
   }

sub FIRSTKEY
   {
   my $a = scalar keys %{$_[0]->{'_DATA'}};
   return each %{$_[0]->{'_DATA'}};
   }

sub NEXTKEY
   {
   return each %{$_[0]->{'_DATA'}};
   }

sub EXISTS
   {
   return exists $_[0]->{'_DATA'}->{$_[1]};
   }

sub DELETE
   {
   ## force a re-sort on next fetch
   $_[0]->{'_SORT'} = 1;
   delete $_[0]->{'_DATA'}->{$_[1]};
   }

sub CLEAR
   {
   ## force a re-sort on next fetch
   $_[0]->{'_SORT'} = 1;
   %{$_[0]->{'_DATA'}} = ();
   }

sub STORE
   {
   my ($self, $key, $val) = @_;

   ## the key must be a number
   croak "key ($key) must be a number" if ref $key ||
      ! looks_like_number($key);

   ## the value must be a number
   croak "val ($val) must be a number" if ref $val ||
      ! looks_like_number($val);

   ## force key to number
   $key += 0;

   ## force a re-sort on next fetch
   $self->{'_SORT'} = 1;

   $self->{'_DATA'}{$key} = $val;

   }

sub FETCH
   {
   my ($self, $key) = @_;

   croak "key ($key) must be a number" if ref $key ||
      ! looks_like_number($key);

   ## force key to number
   $key += 0;

   ## return right away for direct hits
   return $self->{'_DATA'}{$key} if exists $self->{'_DATA'}{$key};

   ## re-sort keys if necessary
   _sort_keys($self) if $self->{'_SORT'};

   my @keys = @{ $self->{'_KEYS'} };

   ## be sure we have at least 1 key
   croak "cannot interpolate/extrapolate with less than two keys"
      if @keys < 1;

   ## return constant if only 1 key
   if (@keys == 1)
      {

      ## determine whether we should die, return undef, or extrapolate
      my $one_key_opt = $self->{'_OPTS'}{'one_key'};

      $one_key_opt eq ONE_KEY_FATAL ? croak "cannot extrapolate with only one key" :
      $one_key_opt eq ONE_KEY_UNDEF ? return undef : ();

      return $self->{'_DATA'}{$keys[0]};
      }

   ## begin interpolation/extrapolation search
   my ($lower, $upper);

   ## key is below range of known keys
   if ($key < $keys[0])
      {

      my $extrap_opt = $self->{'_OPTS'}{'extrapolate'};

      $extrap_opt eq EX_CONSTANT ? return $self->{'_DATA'}{$keys[0]} :
      $extrap_opt eq EX_FATAL    ? croak "fatal extrapolation with key ($key)" :
      $extrap_opt eq EX_UNDEF    ? return undef : ();

      ($lower, $upper) = @keys[0, 1];

      }
   ## key is above range of known keys
   elsif ($key > $keys[-1])
      {

      my $extrap_opt = $self->{'_OPTS'}{'extrapolate'};

      $extrap_opt eq EX_CONSTANT ? return $self->{'_DATA'}{$keys[-1]} :
      $extrap_opt eq EX_FATAL    ? croak "fatal extrapolation with key ($key)" :
      $extrap_opt eq EX_UNDEF    ? return undef : ();

      ($lower, $upper) = @keys[-2, -1];

      }
   ## key is within range of known keys
   else
      {

      for my $i (0 .. $#keys - 1)
         {
         ($lower, $upper) = @keys[$i, $i+1];
         last if $key <= $upper;
         croak "unable to find bracketing keys" if $i == $#keys - 1;
         }

      }

   return _mx_plus_b($key, $lower, $upper, $self->{'_DATA'}{$lower},
      $self->{'_DATA'}{$upper});

   }

## sort keys and reset flag
sub _sort_keys
   {
   my ($self) = @_;
   $self->{'_KEYS'} = [ sort { $a <=> $b } keys %{ $self->{'_DATA'} } ];
   $self->{'_SORT'} = 0;
   }

## basic equation for a line given 2 points
sub _mx_plus_b
   {
   my ($x, $x1, $x2, $y1, $y2) = @_;
   my $slope     = ($y2 - $y1) / ($x2 - $x1);
   my $intercept = $y2 - ($slope * $x2);
   return $slope * $x + $intercept;
   }

1;
__END__

=head1 NAME

Tie::Hash::Interpolate - tied mathematical interpolation/extrapolation

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

   use Tie::Hash::Interpolate;

   ## use tie interface

   tie my %lut, 'Tie::Hash::Interpolate', extrapolate => 'linear';

   $lut{3} = 4;
   $lut{5} = 6;

   print $lut{4};    ## prints 5
   print $lut{6.5};  ## prints 7.5

   ## or constructor interface

   my $lut = Tie::Hash::Interpolate->new( extrapolate => 'linear' );

   $lut->{3} = 4;
   $lut->{5} = 6;

   print $lut->{4};    ## prints 5
   print $lut->{6.5};  ## prints 7.5

=head1 DESCRIPTION

C<Tie::Hash::Interpolate> provides a mechanism for using a hash as a lookup
table for interpolated and extrapolated values.

Hashes can either be tied using the C<tie> builtin or by constructing one with
the C<new()> method.

After your hash is tied (NOTE: key-value pairs added prior to the tie will be
ignored), insert your known key-value pairs. If you then fetch a key that does
not exist, an interpolation or extrapolation will be performed as necessary. If
you fetch a key that does exist, the value stored for that key will be
returned.

=head1 FUNCTIONS

=head2 new

=cut

=head1 OPTIONS

Options can be passed to C<tie> after the C<Tie::Hash::Interpolate> name is
given, or directly to C<new()> as key-value pairs.

   tie my %lut, 'Tie::Hash::Interpolate', extrapolate => 'fatal';

   ## or

   my $lut = Tie::Hash::Interpolate->new( one_key => 'constant' );

=head2 C<extrapolate>

This option controls the behavior of the tied hash when a key is requested
outside the range of known keys. Valid C<extrapolate> values include:

=over 4

=item * C<linear> (I<default>)

extrapolate linearly based on the two nearest points

=item * C<constant>

keep the nearest value constant rather than extrapolating

=item * C<fatal>

throw a fatal exception

=item * C<undef>

return C<undef>

=back

=head2 C<one_key>

This option controls the behavior of the tied hash when a key is requested and
only one key exists in the hash. Valid C<one_key> values include:

=over 4

=item * C<fatal> (I<default>)

throw a fatal exception

=item * C<constant>

all fetches return the one value that exists

=item * C<undef>

return C<undef>

=back

=head1 TO DO

=over 4

=item - support multiple dimensions

=item - support autovivification of tied hashes

=item - set a per-instance mode for insertion or lookup

=item - be smarter (proximity based direction) about searching when doing
        interpolation

=back

=head1 AUTHOR

Daniel B. Boorstein, E<lt>danboo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Daniel B. Boorstein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
