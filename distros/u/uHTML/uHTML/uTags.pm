
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
# Roland Mosler, Place.Ug
#



use strict ;
use uHTML ;
use uHTML::ListFuncs( 'uniq' ) ;

use version ; our $VERSION = "1.0" ;


sub List_uHTML_Tags( $ )
{
  my( $Node,$Par,$Var,$Head,$Join,$Tail ) = @_ ;

  unless( $Par )
  {
    $Join = $Node->codeAttr( 'join' ) ;
    $Head = $Node->codeAttr( 'head' ) ;
    $Tail = $Node->codeAttr( 'tail' ) ;
  }

  return $Head.join( $Join,uniq sort uHTML::tags() ).$Tail ;
}

sub List_uHTML_Vars( $ )
{
  my( $Node,$Par,$Var,$Head,$Join,$Tail ) = @_ ;

  unless( $Par )
  {
    $Join = $Node->codeAttr( 'join' ) ;
    $Head = $Node->codeAttr( 'head' ) ;
    $Tail = $Node->codeAttr( 'tail' ) ;
  }

  return $Head.join( $Join,sort uHTML::vars() ).$Tail ;
}

sub Test_uHTML_Tag
{
  my( $Node,$Par,$Var,$Name,$Ret ) = @_ ;
  $Name= $Node->attr( 'name' ) and $Ret = $Node->attr( 'msg' ) unless $Par ;
  return '' unless $Name ;
  $Ret = 1  unless $Ret ;
  return( uHTML::testTag( $Name ) ? $Ret : '' ) ;
}

sub Test_uHTML_Var
{
  my( $Node,$Par,$Var,$Name,$Ret ) = @_ ;
  $Name= $Node->attr( 'name' ) and $Ret = $Node->attr( 'msg' ) unless $Par ;
  return '' unless $Name ;
  $Ret = 1 unless $Ret ;
  return( uHTML::testVar( $Name ) ? $Ret : '' ) ;
}


uHTML::register( 'uhtmlTL',\&List_uHTML_Tags ) ;
uHTML::register( 'ListTags',\&List_uHTML_Tags ) ;
uHTML::register( 'ListVars',\&List_uHTML_Vars ) ;
uHTML::register( 'TestTag',\&Test_uHTML_Tag ) ;
uHTML::register( 'TestVar',\&Test_uHTML_Var ) ;



######################################
######################################

=pod

=encoding UTF-8

=head1 NAME

=over 2

=item B<uHTML::uTags> - Testing B<uHTML> tags and functions for existence

=back

=head1 VERSION

Version 1.0

=head1 DESCRIPTION

The library B<uHTML::uTags> provides tags and functions to check the existence of an
particular B<uHTML>-tag or function. This library is thought mainly as a debug tool
for the designer and rarely of practical use in working websites.

Requirements

The B<uHTML::uTags> library requires the B<uHTML>::listfuncs library and the main B<uHTML> library.



B< >

=head1 B<uHTML> tags provided by the uHTML::uTags library

B< >

=head2 ListTags

=head3 Overview

The ListTags tag lists all B<uHTML> tags with associated program code.

=head3 Attributes

=head4 head="text"

The attribute head defines the text preceding the tag list.

=head4 join="text"

The attribute join defines the text between two consecutive tag names.

=head4 tail="text"

The attribute tail defines the text following the tag list.

=head3 Example

  <ListTags head="Known tags: " join=", " tail=".">

=head2 ListVars

=head3 Overview

The ListVars tag lists all known B<uHTML> attribute variables.

=head3 Attributes

=head4 head="text"

The attribute head defines the text preceding the variables list.

=head4 join="text"

The attribute join defines the text between two consecutive variables names.

=head4 tail="text"

The attribute tail defines the text following the variables list.

=head3 Example

  <ListVars head="Known variables: " join=", " tail=".">

=head2 TestTag

=head3 Overview

The TestTag tag tests if a particular B<uHTML> tag has program code associated with it.

=head3 Attributes

=head4 name="text"

Name of the tested tag.

=head4 msg="text"

Message displayed in case the tag name has code connected to it.

=head3 Example

  <TestTag name="if" msg="<b>if</b> is defined.">

=head2 TestVar

=head3 Overview

The TestVar tag tests if a particular B<uHTML> attribute variable is known.

=head3 Attributes

=head4 name="text"

Name of the tested variable.

=head4 msg="text"

Message displayed in case the variable name is known.

=head3 Example

  <TestVar name="RepeatValue" msg="<b>RepeatValue</b> is defined as variable.">


B< >

B< >

=head1 Attribute variables and functions provided by the uHTML::uTags library

B< >

=head2 $ListTags(head,join,tail)

=head3 Overview

The ListTags function returns a list of all B<uHTML> tags associated with program code.

=head3 Parameters

=head4 head

The parameter head defines the text preceding the tag list.

=head4 join

The parameter join defines the text between two consecutive tag names.

=head4 tail

The parameter tail defines the text following the tag list.

=head3 Example

  <uList elements="$ListTags('',',','')">
    ...
  </uList>

=head2 $ListVars(head,join,tail)

=head3 Overview

The ListVars function returns a list of all known B<uHTML> attribute variables.

=head3 Parameters

=head4 head

The parameter head defines the text preceding the variables list.

=head4 join

The parameter join defines the text between two consecutive variables names.

=head4 tail

The parameter tail defines the text following the variables list.

=head3 Example

  <uList elements="$ListVars('',',','')">
    ...
  </uList>

=head2 $TestTag(name,ret)

=head3 Overview

The $TestTag function tests if a particular B<uHTML> tag has program code associated with it.

=head3 Parameters

=head4 name

Name of the tested tag.

=head4 msg

Value returned in case the tag name has code connected to it.

=head3 Example

  <if cond="$TestTag(include,1)">Tag "include" is defined.</if>

=head2 $TestVar(name,ret)

=head3 Overview

The $TestVar function tests if a particular B<uHTML> attribute variable is known.

=head3 Parameters

=head4 name

Name of the tested attribute variable.

=head4 ret

Value returned in case the attribute variable name is known.

=head3 Example

  <if cond="$TestVar(RepeatValue,1)">RepeatValue is defined.</if>


=head1 SEE ALSO

perl(1), uHTML, uHTML::ListFuncs, http://www.uhtml.de/en/doc/uTags.uhtml



=head1 AUTHOR

Roland Mosler (Roland.Mosler@Place.Ug)

=head1 COPYRIGHT

Copyright 2009 Roland Mosler.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

