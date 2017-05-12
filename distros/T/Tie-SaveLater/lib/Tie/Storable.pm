#
# $Id: Storable.pm,v 0.3 2006/03/22 22:10:28 dankogai Exp $
#
package Tie::Storable;
use strict;
use warnings;
use base 'Tie::SaveLater';
our $VERSION = sprintf "%d.%02d", q$Revision: 0.3 $ =~ /(\d+)/g;
use Storable ();
use Carp;
__PACKAGE__->make_subclasses;
sub load{ Storable::retrieve($_[1]) };
sub save{ Storable::nstore($_[0], $_[0]->filename) };

####
package Tie::Storable::More;
use base 'Tie::SaveLater';
use Carp;
__PACKAGE__->make_subclasses;

sub load{ 
    my ($class, $filename) = @_;
    return Storable::retrieve($filename)
};

sub save{
    my $self = shift;
    if (my @options = $self->options){
	return 1 unless ($options[0] & 0222); # do nothing if read-only
    }
    return Storable::nstore($self, $self->filename) 
};

sub STORE{
    my $self = shift;
    if (my @options = $self->options){
	croak "This variable is read-only!" unless ($options[0] & 0222);
    }
    return $self->super_super('STORE' => @_);
}

1;
__END__

=head1 NAME

Tie::Storable - Stores your object when untied via Storable

=head1 SYNOPSIS

  use Tie::Storable;
  {
      tie my $scalar => 'Tie::Storable', 'scalar.po';
      $scalar = 42;
  } # scalar is automatically saved as 'scalar.po'.
  {
      tie my @array => 'Tie::Storable', 'array.po';
      @array = qw(Sun Mon Tue Wed Fri Sat);
  } # array is automatically saved as 'array.po'.
  {
      tie my %hash => 'Tie::Storable', 'hash.po';
      %hash = (Sun=>0, Mon=>1, Tue=>2, Wed=>3, Thu=>4, Fri=>5, Sat=>6);
  } # hash is automatically saved as 'hash.po'.
  {
      tie my $object => 'Tie::Storable', 'object.po';
      $object = bless { First => 'Dan', Last => 'Kogai' }, 'DANKOGAI';
  } # You can save an object; just pass a scalar
  {
      tie my $object => 'Tie::Storable', 'object.po';
      $object->{WIFE} =  { First => 'Naomi', Last => 'Kogai' };
      # you can save before you untie like this
      tied($object)->save;
  }

=head1 DESCRIPTION

Tie::Storable stores tied variables when untied.  Usually that happens
when you variable is out of scope.  You can of course explicitly untie
the variable or C<< tied($variable)->save >> but the whole idea is not
to forget to save it.

This module uses L<Storable> as its backend so it can store and
retrieve anything that L<Storable> can.

=head1 SEE ALSO

L<Tie::SaveLater>, L<Tie::Storable>, L<Tie::YAML>

L<perltie>, L<Tie::Scalar>, L<Tie::Array>, L<Tie::Hash>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

