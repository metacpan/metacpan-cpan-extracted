# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and 
# related or neighboring rights.  Attribution is requested but is not required.
# $Id: Indirect.pm,v 1.9 2021/12/22 20:35:22 jima Exp jima $

=pod

=head1 NAME

Tie::Indirect::* -- tie variables to access data located at run-time.

=head1 DESCRIPTION

  Each tied variable accesses data located by calling a sub
  which returns a reference to the data.  
 
  The sub is called with parameters ($mutating, optional tie args...)
  where $mutating is true if the access may modify the value. 
 
  tie $scalar, 'Tie::Indirect::Scalar', \&sub, optional tie args...
  tie @array,  'Tie::Indirect::Array',  \&sub, optional tie args...
  tie %hash,   'Tie::Indirect::Hash',   \&sub, optional tie args...
 
  EXAMPLE:
    my $dataset1 = { foo=>123, table=>{...something...}, list=>[...] };
    my $dataset2 = { foo=>456, table=>{...something else...}, list=>[...] };
 
    my $masterref;
 
    our ($foo, %table, @list);
    tie $foo,   'Tie::Indirect::Scalar', sub{ \$masterref->{$_[1]} }, 'foo';
    tie %table, 'Tie::Indirect::Hash',   sub{ $masterref->{$_[1]} }, 'table; 
    tie @list,  'Tie::Indirect::Array',  sub{ $masterref->{list} };
 
    $masterref = $dataset1;
    ... $foo, %table, and @list now access members of $dataset1
    $masterref = $dataset2;
    ... $foo, %table, and @list now access members of $dataset2
 
=head1 AUTHOR / LICENSE

Jim Avera (jim.avera AT gmail) / Public Domain or CC0

=cut

#---------------------------------------------------------------------#
package Tie::Indirect; # just so Dist::Zilla can add $VERSION
$Tie::Indirect::VERSION = '0.001';

package 
  Tie::Indirect::Scalar;
use Carp;

sub TIESCALAR {
    my ($class, $subref, @extras) = @_;
    croak "not a code ref" unless ref($subref) eq 'CODE';
    return bless [$subref, @extras], $class
}
sub _getref {
    my ($self, $mutating) = @_;
    return $self->[0]->($mutating, @{$self}[1..$#$self]);
}
sub FETCH   { ${ $_[0]->_getref()  } }
sub STORE   { ${ $_[0]->_getref(1) } = $_[1] }

## Ignore death of the helper sub called from DESTROY
#sub DESTROY { eval { undef ${ $_[0]->_getref(1) } }; }

#---------------------------------------------------------------------#
package 
  Tie::Indirect::Array;
use Carp;

sub TIEARRAY {
    my ($class, $subref, @extras) = @_;
    croak "not a code ref" unless ref($subref) eq 'CODE';
    return bless [$subref, @extras], $class
}
sub _getref {
    my ($self, $mutating) = @_;
    return $self->[0]->($mutating, @{$self}[1..$#$self]);
}
# based on code in Tie::StdArray
sub FETCHSIZE { scalar @{$_[0]->_getref()} }
sub STORESIZE { $#{$_[0]->_getref(1)} = $_[1]-1 }
sub STORE     { $_[0]->_getref(1)->[$_[1]] = $_[2] }
sub FETCH     { $_[0]->_getref()->[$_[1]] }
sub CLEAR     { @{$_[0]->_getref(1)} = () }
sub POP       { pop(@{$_[0]->_getref(1)}) }
sub PUSH      { my $o = shift->_getref(1); push(@$o,@_) }
sub SHIFT     { shift(@{$_[0]->_getref(1)}) }
sub UNSHIFT   { my $o = shift->_getref(1); unshift(@$o,@_) }
sub EXISTS    { exists $_[0]->_getref()->[$_[1]] }
sub DELETE    { delete $_[0]->_getref(1)->[$_[1]] }
sub SPLICE
{
 my $ob  = shift;
 my $sz  = $ob->FETCHSIZE;
 my $off = @_ ? shift : 0;
 $off   += $sz if $off < 0;
 my $len = @_ ? shift : $sz-$off;
 return splice(@{$ob->_getref(1)},$off,$len,@_);
}
sub EXTEND    { }

#---------------------------------------------------------------------#
package 
  Tie::Indirect::Hash;
require Tie::Hash;
use Carp;

sub TIEHASH {
    my ($class, $subref, @extras) = @_;
    croak "not a code ref" unless ref($subref) eq 'CODE';
    return bless [$subref, @extras], $class
}
sub _getref {
    my ($self, $mutating) = @_;
    return $self->[0]->($mutating, @{$self}[1..$#$self]);
}
# based on code in Tie::StdHash
sub STORE    { $_[0]->_getref(1)->{$_[1]} = $_[2] }
sub FETCH    { $_[0]->_getref()->{$_[1]} }
sub FIRSTKEY { my $o = $_[0]->_getref(); my $a = scalar keys %{$o}; each %{$o} }
sub NEXTKEY  { each %{$_[0]->_getref()} }
sub EXISTS   { exists $_[0]->_getref()->{$_[1]} }
sub DELETE   { delete $_[0]->_getref(1)->{$_[1]} }
sub CLEAR    { %{$_[0]->_getref(1)} = () }
sub SCALAR   { scalar %{$_[0]->_getref()} }

1;
