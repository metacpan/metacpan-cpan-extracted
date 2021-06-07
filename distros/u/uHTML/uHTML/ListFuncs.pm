

#
# Author: Roland Mosler - Roland@Place.Ug
#
# Das ist eine uHTML-Bibliothek von Place.Ug
# Es ist erlaubt dieses Paket unter der aktuellen GNU LGPL zu nutzen
# Bei Weiterentwicklungen ist die Ursprungsbibliothek zu nennen
#
# Fehler und Verbesserungen bitte an uHTML@Place.Ug
#
# This is a uHTML library from Place.Ug
# It is allowed to use this library under the actual GNU LGPL
# The name of this library is to be named in all derivations
#
# Please report errors to uHTML@Place.Ug
#
# � Roland Mosler, Place.Ug
#



use strict;

package uHTML::ListFuncs ;

use version ; our $VERSION = "0.81" ;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( uniq section difference shuffle sample );  # symbols to export on request


sub uniq
{
  my( $old,@out ) ;

  foreach( @_ )
  {
    push @out,($old = $_) unless( $old eq $_ ) ;
  }
  return @out ;
}

sub section_old
{
  my( $n ) = $#_ ;

  return( ref $_[0] eq 'ARRAY' ? @{$_[0]} : () ) unless $n > 0 ;

  my( @T,@O,$old,$i ) ;

  foreach( @_ )
  {
    push @T,@{$_} if ref eq 'ARRAY' ;
  }
  $old = '' ;
  foreach( sort @T )
  {
    if( $old eq $_ )
    {
      push @O,$_ unless --$i ;
    }
    else
    {
      $old = $_ ;
      $i   = $n ;
    }
  }
  return @O ;
}

sub section
{
  my( $n ) = $#_ ;

  return( ref $_[0] eq 'ARRAY' ? @{$_[0]} : () ) unless $n > 0 ;

  my( @T,@P,@R,$i,$v,$c ) ;

  foreach( @_ )
  {
    next unless ref eq 'ARRAY' ;
    return () unless @{$_} ;
    my @A = uniq sort @{$_} ;
    push @T,\@A ;
  }
  for( $v=$T[0]->[0]; @{$T[0]}; )
  {
    for( $i=0; $i<=$#T; $i++ )
    {
      while( $T[$i]->[0] lt $v )
      {
        shift @{$T[$i]} ;
        return @R unless @{$T[$i]} ;
      }
      if( $T[$i]->[0] gt $v )
      {
        $v = $T[$i]->[0] ;
        last ;
      }
    }
    if( $i>$#T )  # all the same
    {
      push @R,$v ;
      shift @{$T[0]} ;
      return @R unless @{$T[0]} ;
      $v = $T[0]->[0] ;
    }
  }
  return @R ;
}

sub difference( $$ )
{
  return ()       unless ref $_[0] eq 'ARRAY' and @{$_[0]} ;
  return @{$_[0]} unless ref $_[1] eq 'ARRAY' and @{$_[1]} ;
  my @M = sort @{$_[0]} ;
  my @S = sort @{$_[1]} ;
  my( @O,$i,$j ) ;

  for( $i=$j=0; $i<=$#M; $i++ )
  {
    $j++ while( $j<=$#S and $M[$i] gt $S[$j] ) ;
    push @O,$M[$i] unless $j<=$#S and $M[$i] eq $S[$j] ;
  }
  return @O ;
}

sub shuffle
{
  return unless ref(my $A = shift) eq 'ARRAY' ;

  my( $i,$k ) ;

  for( $k=$#{$A}; $k>0; $k-- )
  {
    ($i = int(rand($k+1))) < $k and ($A->[$k],$A->[$i]) = ($A->[$i],$A->[$k]) ;
  }
  return $A ;
}

sub sample
{
  my( $List,$length ) = @_ ;
  return undef unless ref $List eq 'ARRAY' and $length > 0 ;
  return $List unless $length < @{$List} ;

  my( $i,$j,$r,@SL ) ;

  $r = scalar(@{$List})/$length ;
  $j = 0 ;
  while( $j<@{$List} )
  {
    $i = $j ;
    $j = int( $i + $r + 0.5 ) ;
    push @SL,$List->[$i+1<$j ? int($i + rand($j - $i) + 0.5) : $i] ;
  }
  return \@SL ;
}

1;

__END__

######################################
######################################

=pod

=encoding UTF-8

=head1 NAME

=over 2

=item B<uHTML::ListFuncs> - More list functions for B<perl>

=back

=head1 VERSION

Version 0.81

=head1 DESCRIPTION

This library provides the functions sample, shuffle, uniq, section and difference for perl.
This library is used by many of the B<uHTML> libraries. It can be of use without B<uHTML> as well.



B< >

=head1 perl functions provided by the B<hHTML::ListFuncs> library

B< >



=head2 uniq(@list)

=head3 Overview

The function uniq removes identical consecutive values from @list and returns the result, similar to uniq from GNU core utils.

=head3 Parameters

=head4 @list

List to process.

=head3 Example

  foreach( uniq sort @list ) {...}

=head2 section($list1,$list2,$list3,...)

=head3 Overview

The function section computes the section of several lists.

=head3 Parameters

=head4 $list1,$list2,...

References of lists from which the section has to be computed.

=head3 Example

  foreach( section( \@list1,\@list2 ) ) {...}

=head2 difference($list1,$list2)

=head3 Overview

The function difference removes from @{$list1} all elements contained in @{$list2}.

=head3 Parameters

=head4 $list1

Reference of the original list from which elements will be removed.

=head4 $list2

References of list with elements that will be removed from @{$list1}.

=head3 Example

  foreach( difference( \@list1,\@list2 ) ) {...}

=head2 shuffle($list)

=head3 Overview

The function shuffle shuffles randomly @{$list}.

=head3 Parameters

=head4 $list

Reference of the list to be shuffled

=head3 Example

  shuffle( \@list ) ;

=head2 sample($list,$count)

=head3 Overview

The function sample selects more or less evenly picked $count random elements from @{$list1}. The function returns a reference to a list with the samples.

=head3 Parameters

=head4 $list

Reference of the list from which elements will be picked.

=head4 $count

Count of elements to be picked from @{$list}.

=head3 Example

  foreach( @{sample( \@list,$count )} ) {...}




=head1 SEE ALSO

perl(1), http://www.uhtml.de/en/doc/ListFuncs.uhtml



=head1 AUTHOR

Roland Mosler (Roland.Mosler@Place.Ug)

=head1 COPYRIGHT

Copyright 2009 Roland Mosler.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


