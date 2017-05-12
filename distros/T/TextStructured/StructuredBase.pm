=head1 NAME

Text::StructuredBase - Structured text base class

=head1 SYNOPSIS

  use base qw/Text::StructuredBase/;

  $object->debug($n);

=head1 DESCRIPTION

I<Text::StructuredBase> acts as a base class for B<Text::Structured>.

=cut

package Text::StructuredBase;
use strict;
use vars qw($AUTOLOAD);
use Carp;

## CLASS DATA

my $Debugging = 0;

=head1 BASE CLASS METHODS

=head2 AUTOLOAD()

AUTOLOAD() provides default accessor methods (apart from DESTROY())
for any of its subclasses.  For AUTOLOAD() to catch calls to these
methods objects must be implemented as an anonymous hash.  Object
attributes must

=over 4

=item *) have UPPER CASE names

=item *) have keys in attribute _PERMITTED (an anonymous hash)

=back

The name accessor method is the name of the attribute in B<lower
case>.  The 'set' versions of these accessor methods require a single
scalar argument (which could of course be a reference.)  Both 'set'
and 'get' versions return the attribute's value.

B<Special Attributes>

=over 4

=item B</_L$/>

Attribute names matching the pattern B</_L$/> will be treated as
arrayrefs.  These accessors require an arrayref as an argument.  If
the attribute is defined they return the arrayref, otherwise they
return an empty arrayref.

A method B<*_l_add(@foo)> can be called on this type of attribute to
add the elements in I<@foo> to the array.  If the attribute is defined
they return the arrayref, otherwise they return an empty arrayref.

=item B</_H$/>

Attribute names matching the pattern B</_H$/> will be treated as
hashrefs.  These accessors require a reference to an array containing
key/value pairs.  If the attribute is defined they return the hashref,
otherwise they return an empty hashref.

A method B<*_h_byname(@list)> can be called on this type of attribute.
These methods will return a list which is the hash slice of the B<_H>
attribute value over I<@list> or an empty list if the attribute is
undefined.

A method B<*_h_add(\%foo)> can be called on this type of attribute to
add the elements in I<%foo> to the hash.  If the attribute is defined
they return the hashref, otherwise they return an empty hashref.

=back

=cut

sub AUTOLOAD {
  my $self  = shift;
  my $type  = ref($self) or die "$self is not an object";
  warn "AUTOLOAD($AUTOLOAD)" if $self->{_DEBUG} || $Debugging;

  my $method = $AUTOLOAD;
  $method =~ s/.*://;     # strip fully-qualified portion

  # accessor methods
  $method = uc($method);
  return if ( $method eq 'DESTROY' );  # don't catch 'DESTROY'
  my $name = $method;
  $name =~ s/_H_BYNAME|_H_ADD$/_H/;
  $name =~ s/_L_ADD$/_L/;
  unless ( exists $self->{_PERMITTED}->{$name} ) {
    die "Can't access `$name' field in class $type";
  }

  print STDERR "\$_[0] = ",defined($_[0]) ? $_[0] : 'undef',"\n"
    if $self->{_DEBUG};

  if ( $method =~ /_L$/ ) {             # set/get array
    @{$self->{$name}} = @{$_[0]} if $_[0];
    return defined($self->{$name}) ? $self->{$name} : [];
  } elsif ( $method =~ /_L_ADD$/ ) {    # add to array
    print STDERR "\@_ = @_\n" if $self->{_DEBUG};
    push(@{$self->{$name}},@_);
    return defined($self->{$name}) ? $self->{$name} : [];
  } elsif ( $method =~ /_H$/ ) {        # set/get hash
    %{$self->{$name}} = @{$_[0]} if $_[0];
    return defined($self->{$name}) ? $self->{$name} : {};
  } elsif ( $method =~ /_H_ADD$/ ) {    # add to hash
    while ( my($k,$v) = each(%{$_[0]}) ) { $self->{$name}->{$k} = $v }
    return defined($self->{$name}) ? $self->{$name} : {};
  } elsif ( $method =~ /_H_BYNAME$/ ) { # get hash values by name
    print STDERR "$self $name byname: @_\n" if $self->{_DEBUG};
    return defined($self->{$name}) ? @{$self->{$name}}{@_} : ();
  }
  else {                                # set/get scalar
    return @_ ? $self->{$name} = shift : $self->{$name};
  }
}

#------------------------------------------------------------------------------

=head2 debug($n)

As a class method sets the class attribute I<$Debugging> to I<$n>.  As
an object method sets the object attribute I<$_DEBUG> to I<$n>.

=cut

sub debug {
  my $self = shift;
  confess "usage: thing->debug(level)" unless @_ == 1;
  my $level = shift;
  if (ref($self))  {
    $self->{"_DEBUG"} = $level;         # just myself
  } else {
    $Debugging        = $level;         # whole class
  }
}


1;

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
