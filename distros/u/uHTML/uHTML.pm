

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
# © Roland Mosler, Place.Ug
#


use strict ;

use version ; our $VERSION = "1.2" ;

package uHTMLnode;


#
# Node ->
#
# FirstChild:   - Erstes Unterelement
# LastChild:    - Letztes Unterelement
# Parent:       - Darüberliegendes Element
# Name:         - Elementname
# End:          - Eins wenn das Element abgeschlossen ist
# Attributes:   - Elmentattribute als Hash-Referenz
# Text:         - Elementtext bis zum ersten Unterelement oder Nachfolger
# Trailer:      - Text nach dem Abschluß
# XMLClose:     - Eins wenn vor '>' ein '/' kommt
# tainted       - Node->insert() wiederholen
# B<HTML>          - Finaler HTML-Code
# ENV           - Zeiger zur Umgebung


sub new($$$$)
{
  my( $class,$Name,$Text,$Prev,$E ) = @_ ;

  my $Element ;

  $Element->{Name}    = $Name ;
  $Element->{Trailer} = $Text ;
  $Element->{ENV}     = $E ;

  bless( $Element,$class ) ;

  if( ref $Prev eq $class )
  {
    if( ref $Prev->{Parent} eq $class )
    {
      $Prev->{Parent}->addChild( $Element,$Prev ) ;
    }
    else
    {
      $Element->{Prev} = $Prev ;
      $Element->{Next} = $Prev->{Next} ;
      $Prev->{Next}    = $Element ;
    }
  }

  return $Element ;
}

sub name
{
  my $Node = shift;

  $Node->{Name} = shift if @_ ;
  return $Node->{Name} ;
}

sub text
{
  my $Node = shift;

  $Node->{Text} = join '',@_ if @_ ;
  return $Node->{Text} ;
}

sub parent
{
  my $Node   = shift ;
  my $Parent = shift ;

  if( ref $Parent eq 'uHTMLnode' and $Parent != $Node->{Parent} )
  {
    $Node->detach(1) ;
    $Parent->addChild( $Node ) ;
    $Node->{Parent} = $Parent ;
  }
  return $Node->{Parent} ;
}

sub prev
{
  my $Node = shift ;
  my $Prev = shift ;

  if( ref $Prev eq 'uHTMLnode' )
  {
    $Prev->detach(1) ;
    my $Parent = $Node->{Parent} ;
    if( ref $Parent eq 'uHTMLnode' )
    {
      $Parent->{FirstChild} = $Prev if $Parent->{FirstChild} == $Node ;
      $Prev->{Parent}       = $Parent ;
    }
    $Prev->{Prev} = $Node->{Prev} ;
    $Prev->{Next} = $Node ;
    $Node->{Prev} = $Prev ;
  }
  return $Node->{Prev} ;
}

sub next
{
  my $Node = shift;
  my $Next = shift ;

  if( ref $Next eq 'uHTMLnode' )
  {
    $Next->detach(1) ;
    my $Parent = $Node->{Parent} ;
    if( ref $Parent eq 'uHTMLnode' )
    {
      $Parent->{LastChild} = $Next if $Parent->{LastChild} == $Node ;
      $Next->{Parent}      = $Parent ;
    }
    $Next->{Prev} = $Node ;
    $Next->{Next} = $Node->{Next} ;
    $Node->{Next} = $Next ;
  }
  return $Node->{Next} ;
}

sub firstChild
{
  my $Node = shift ;
  my $FC   = shift ;

  if( ref $FC eq 'uHTMLnode' and $FC != $Node )
  {
    $FC->detach(1) ;
    $Node->addChild( $FC ) ;
  }
  return $Node->{FirstChild} ;
}

sub lastChild
{
  my $Node = shift ;
  my $LC   = shift ;

  if( ref $LC eq 'uHTMLnode' and $LC != $Node )
  {
    $LC->detach(1) ;
    $Node->appendChild( $LC ) ;
  }
  return $Node->{LastChild} ;
}

sub addChild
{
  my $Node = shift;
  my $new  = shift;
  my $prev = shift;

  return undef unless ref $new  eq 'uHTMLnode' and $new != $Node ;
  return $new  unless $new->{Parent} != $Node ;
  $new->detach()   if $new->{Parent} or $new->{Prev} or $new->{Next} ;
  undef $prev  unless ref $prev eq 'uHTMLnode' and $prev->{Parent} == $Node ;

  if( $prev )
  {
    ($new->{Next} = $prev->{Next}) ? ($prev->{Next}->{Prev}=$new) : ($Node->{LastChild}=$new) ;
    $new->{Prev}  = $prev ;
    $prev->{Next} = $new  ;
  }
  else
  {
    ($new->{Next} = $Node->{FirstChild}) ? ($new->{Next}->{Prev}=$new) : ($Node->{LastChild}=$new) ;
    $new->{Prev}  = undef ;
    $Node->{FirstChild} = $new  ;
  }
  $new->{Parent} = $Node ;

  return $new ;
}

sub appendChild( $ )
{
  my $Node = shift;
  my $new  = shift;

  return $Node->addChild( $new, $Node->{LastChild} ) ;
}

sub findChild
{
  my $Node  = shift;
  my $name  = shift;
  my $child = shift;
  my( $C,$R ) ;

  return undef unless $name ne '' and $Node->{FirstChild} ;
  undef $child unless ref $child eq 'uHTMLnode' and $child != $Node ;

  for( $C = $Node->{FirstChild}; $C; $C=$C->{Next} )
  {
    $C == $child and undef $child, next if $child ;
    return $C                           if $name eq $C->{Name} ;
    return $R                           if $R = $C->findChild( $name,$child ) ;
  }
  return undef ;
}

sub adoptChildren
{
  my $Node  = shift;
  my $from  = shift;
  my $child = shift;
  my( $C,$F,$L ) ;

  return undef unless ref $from eq 'uHTMLnode' and $from->{FirstChild} ;
  for( $C=$from; $C; $C=$C->{Parent} )
  {
    return undef if $C == $Node ;
  }
  undef $child unless ref $child eq 'uHTMLnode' and $child->{Parent} == $Node ;

  for( $F=$C=$from->{FirstChild}; $C; $C=$C->{Next} )
  {
    $C->{Parent} = $Node ;
    $L           = $C ;
  }
  delete $from->{FirstChild} ;
  delete $from->{LastChild} ;

  if( $child )
  {
    if( $child->{Next} )
    {
      $L->{Next}         = $child->{Next} ;
      $L->{Next}->{Prev} = $L ;
    }
    else
    {
      $Node->{LastChild} = $L ;
    }
    $child->{Next} = $F ;
  }
  else
  {
    if( $Node->{FirstChild} )
    {
      $L->{Next}         = $Node->{FirstChild} ;
      $L->{Next}->{Prev} = $L ;
    }
    else
    {
      $Node->{LastChild} = $L ;
    }
    $Node->{FirstChild} = $F ;
  }

  return $F ;
}

sub replace
{
  my $Node  = shift;
  my $new   = shift;
  my $KeepT = shift;
  my $C ;

  return undef unless ref $new eq 'uHTMLnode' ;

  print STDERR "Replace node $Node->{Name} with $new->{Name}\n" ;

  for( $C=$new; $C; $C=$C->{Parent} )
  {
    return undef if $C == $Node ;
  }
  $new->detach() if $new->{Parent} or $new->{Prev} or $new->{Next} ;

  $new->{Prev}    = $Node->{Prev}   ;
  $new->{Next}    = $Node->{Next}   ;
  $new->{Parent}  = $Node->{Parent} ;
  $new->{Trailer} = $Node->{Trailer} if $KeepT ;

  return $Node->detach() ;
}

sub detach
{
  my $Node   = shift ;
  my $KeepT  = shift ;
  my $Parent = $Node->{Parent} ;
  my $Prev   = $Node->{Prev} ;
  my $Next   = $Node->{Next} ;
  my $Child ;

  if( ref $Parent eq 'uHTMLnode' )
  {
    $Parent->{FirstChild} = $Next if $Parent->{FirstChild} == $Node ;
    $Parent->{LastChild}  = $Prev if $Parent->{LastChild}  == $Node ;
    delete $Node->{Parent} ;
  }

  return $Node unless ref $Prev eq 'uHTMLnode' or ref $Next eq 'uHTMLnode' ;

  $Prev->{Next} = $Next if ref $Prev eq 'uHTMLnode' ;
  $Next->{Prev} = $Prev if ref $Next eq 'uHTMLnode' ;

  if( not $KeepT and $Node->{Trailer} )
  {
    if( $Prev )
    {
      $Prev->{Trailer} .= $Node->{Trailer} ;
      delete $Node->{Trailer} ;
    }
    elsif( $Parent )
    {
      $Parent->{Text} .= $Node->{Trailer} ;
      delete $Node->{Trailer} ;
    }
  }

  delete $Node->{Prev} ;
  delete $Node->{Next} ;

  return $Node ;
}

sub delete
{
  my $Node = shift;

  $Node->detach() ;
  $Node->{FirstChild}->delete() while $Node->{FirstChild} ;
  undef $Node ;
}

sub end
{
  my $self = shift;

  $self->{End} = shift if @_ ;
  return $self->{End} ;
}

sub taint
{
  my $self = shift;

  $self->{tainted} = 1 ;
}

sub attributes
{
  my $self = shift ;

  $self->{Attributes} = shift if ref $_[0] eq 'HASH' ;
  return $self->{Attributes} ;
}

sub rawAttr
{
  my $self = shift ;
  my $Name = shift ;

  return undef unless $Name and ((ref $self->{Attributes} eq 'HASH' and $self->{Attributes}->{$Name} ne '') or @_) ;

  if( @_ )
  {
    unless( ref $self->{Attributes} eq 'HASH' )
    {
      my %P ;
      $self->{Attributes} = \%P ;
    }
    $self->{Attributes}->{$Name} = join '',@_ ;
  }
  return $self->{Attributes}->{$Name} ;
}

sub setAttr
{
  my( $Node,$Name,$Value ) = @_ ;
  return $Node->rawAttr( $Name,$Value ) ;
}

sub testAttr
{
  my $self = shift ;
  my $Name = shift ;

  return 1 if $Name and $self->{Attributes} and exists $self->{Attributes}->{$Name} ;
  return 0 ;
}

sub testAnyAttr
{
  my $self = shift ;
  my $Name ;

  return 0 unless $self->{Attributes} ;
  exists $self->{Attributes}->{$Name} and return 1 while $Name = shift ;
  return 0 ;
}

sub testAllAttr
{
  my $self = shift ;
  my $Name = shift  ;

  return 0 unless $Name and $self->{Attributes} and exists $self->{Attributes}->{$Name} ;
  exists $self->{Attributes}->{$Name} or return 0 while $Name = shift ;
  return 1 ;
}

sub addAttr
{
  my $self = shift ;

  $_ and $self->{Attributes}->{$_} = undef foreach @_ ;
}

sub deleteAttr
{
  my $self = shift ;
  my $Name = shift ;

  return 0 unless $Name and defined $self->{Attributes} ;

  my $ret = 0 ;

  while( $Name )
  {
    delete $self->{Attributes}->{$Name},$ret++ if exists $self->{Attributes}->{$Name} ;
    $Name = shift ;
  }

  return $ret ;
}

sub trailer
{
  my $self = shift;

  $self->{Trailer} = shift if @_ ;
  return $self->{Trailer} ;
}

sub XMLClose
{
  my $self = shift;

  $self->{XMLClose} = shift if @_ ;
  return $self->{XMLClose} ;
}

sub env
{
  return $_[0]->{ENV} ;
}

sub HTML
{
  my $self = shift;

  @{$self->{HTML}} = @_ if @_ ;
  return( wantarray ? @{$self->{HTML}} : join( '',@{$self->{HTML}} ) ) ;
}

sub appendText
{
  my $self = shift;

  push @{$self->{HTML}},@_ if @_ ;
}

#-------------------

sub insert # InsertNode
{
  my $Node = shift ;
  my $Text = shift ;
  my( $Child,$p,$a ) ;

  if( $Node->{Name} )
  {
    &{$_}( $Node ) foreach @{$uHTML::uCode{ $Node->{Name} }} ;

    delete $Node->{HTML} ;  # if $Text ;

    if( ref $Node->{Attributes} eq 'HASH' )
    {
      do
      {
        delete $Node->{tainted} ;
        defined $Node->{Attributes}->{$_} and $Node->{Attributes}->{$_} = $Node->codeAttr($_) foreach keys %{$Node->{Attributes}} ;
      } while( $Node->{tainted} ) ;
    }


    push @{$Node->{HTML}},$Node->{Attributes} ?
                          join( ' ',"<$Node->{Name}",map( defined $Node->{Attributes}->{$_} ? (($p=$Node->{Attributes}->{$_} and $p=~m/"/s)?"$_=\'$p\'":"$_=\"$p\"") : $_,
                                                          keys %{$Node->{Attributes}} ) ).'>' :
                          "<$Node->{Name}>" ;



    if( $Text )
    {
      push @{$Node->{HTML}},$Text ;
    }
    else
    {
      push @{$Node->{HTML}},$Node->{Text} if $Node->{Text} ne '' ;
      for( $Child=$Node->{FirstChild}; $Child; $Child=$Child->{Next} )
      {
        push @{$Node->{HTML}},$Child->process() ;
      }
    }
    push @{$Node->{HTML}},"</$Node->{Name}>" if $Node->end() ;
  }
  else
  {
    push @{$Node->{HTML}},$Text,$Node->{Trailer} ;
  }
}

#Bearbeiten des Knotens
sub process()  #ProcessNode
{
  my $Node = shift ;
  my $uhtml ;

  if( $Node->{Name} )
  {
    if( ref $uHTML::uTag{ $Node->{Name} } eq 'CODE' )
    {
      ref eq 'CODE' and &{$_}( $Node ) foreach @{$uHTML::uCode{ $Node->{Name} }} ;
      &{$uHTML::uTag{ $Node->{Name} }}( $Node ) ;
    }
    elsif( ref $uHTML::uSTag{ $Node->{Name} } eq 'CODE' )
    {
      ref eq 'CODE' and &{$_}( $Node ) foreach @{$uHTML::uCode{ $Node->{Name} }} ;
      $uhtml = &{$uHTML::uSTag{ $Node->{Name} }}( $Node,undef,undef ) ;
      @{$Node->{HTML}} = uHTML::recode( $uhtml,$Node->{ENV} ) ;
    }
    else
    {
      $Node->insert() ;
    }
  }

  push @{$Node->{HTML}},$Node->{Trailer} if $Node->{Trailer} ne '' ;
  return ref $Node->{HTML} eq 'ARRAY' ? @{$Node->{HTML}} :  () ;
}

sub map( $$ )
{
  my( $Node,$HeadText,$TailText ) = @_ ;
  my( $T,$C,@HTML ) ;

  if( $HeadText ne '' )
  {
    for( $T = $C = uHTML::_struct( undef,$HeadText,$Node->{ENV} ) ; $C ; $C = $C->{Next} ) { push @HTML,$C->process() }
    $C = $T, $T = $T->{Next}, $C->delete() while $T ;
  }

  push @HTML,$Node->{Text} ;

  for( $C=$Node->{FirstChild}; $C; $C=$C->{Next} ) { push @HTML,$C->process() } ;

  if( $TailText ne '' )
  {
    for( $T = $C = uHTML::_struct( undef,$TailText,$Node->{ENV} ) ; $C ; $C = $C->{Next} ) { push @HTML,$C->process() }
    $C = $T, $T = $T->{Next}, $C->delete() while $T ;
  }


  return( $Node->{HTML} = \@HTML ) ;
}

sub copy()
{
  my $Node  = shift ;
  my $CopyT = shift ;
  my( $Copy,$Prev,$Child,$CC ) ;

  $Copy = uHTMLnode->new( $Node->{Name},undef,undef,$Node->{ENV} ) ;
  $Prev = undef ;

  $Copy->{$_}      = $Node->{$_} foreach qw( Text End XMLClose ) ;
  $Copy->{Trailer} = $Node->{Trailer} if $CopyT ;

  if( $Node->{Attributes} )
  {
    my %Attributes = %{$Node->{Attributes}} ;

    $Copy->{Attributes} = \%Attributes ;
  }

  for( $Child=$Node->{FirstChild}; $Child; $Child=$Child->{Next} )
  {
    $Copy->appendChild( $Child->copy( 1 ) ) ;
  }

  return $Copy ;
}

sub embed($)
{
  my( $Node,$Name ) = @_ ;

  my $ENode = uHTMLnode->new( $Name,'',undef,$Node->{ENV} ) ;

  $ENode->{Parent}     = $Node->{Parent} ;
  $ENode->{Prev}       = $Node->{Prev} ;
  $ENode->{Next}       = $Node->{Next} ;
  $ENode->{FirstChild} = $Node ;
  $ENode->{LastChild}  = $Node ;
  $ENode->{End}        = 1 ;
  $ENode->{Attributes} = undef ;
  $ENode->{Trailer}    = undef ;

  $ENode->{Prev} ? ($ENode->{Prev}->{Next} = $ENode) : ($ENode->{Parent}->{FirstChild} = $ENode) ;
  $ENode->{Next} ? ($ENode->{Next}->{Prev} = $ENode) : ($ENode->{Parent}->{LastChild}  = $ENode) ;

  $Node->{Parent} = $ENode ;
  $Node->{Prev}   = undef ;
  $Node->{Next}   = undef ;

  return $ENode ;
}

sub prepend($)
{
  my $self = shift ;
  my $Node = shift ;

  $Node->{Parent}->{FirstChild} = $Node->{Next} if $Node->{Parent} and $Node->{Parent}->{FirstChild} == $Node ;
  $Node->{Parent}->{LastChild}  = $Node->{Prev} if $Node->{Parent} and $Node->{Parent}->{LastChild}  == $Node ;
  $Node->{Prev}->{Next}         = $Node->{Next} if $Node->{Prev} ;
  $Node->{Next}->{Prev}         = $Node->{Prev} if $Node->{Next} ;

  $Node->{Parent} = $self->{Parent} ;
  $self->{Parent}->{FirstChild} = $Node if $self->{Parent}  and not $self->{Prev} ;
  $Node->{Prev} = $self->{Prev} ;
  $Node->{Next} = $self ;
  $self->{Prev} = $Node ;
}

sub append($)
{
  my $self = shift ;
  my $Node = shift ;

  $Node->{Parent}->{FirstChild} = $Node->{Next} if $Node->{Parent} and $Node->{Parent}->{FirstChild} == $Node ;
  $Node->{Parent}->{LastChild}  = $Node->{Prev} if $Node->{Parent} and $Node->{Parent}->{LastChild}  == $Node ;
  $Node->{Prev}->{Next}         = $Node->{Next} if $Node->{Prev} ;
  $Node->{Next}->{Prev}         = $Node->{Prev} if $Node->{Next} ;

  $Node->{Parent} = $self->{Parent} ;
  $self->{Parent}->{LastChild} = $Node if $self->{Parent}  and not $self->{Next} ;
  $Node->{Prev} = $self ;
  $Node->{Next} = $self->{Next} ;
  $self->{Next} = $Node ;
  $Node->{Trailer} .= $self->{Trailer} ;
  $self->{Trailer} = '' ;
}


sub _close( $$ )
{
  my( $Node,$Name,$Tail ) = @_ ;

  my( $p, $e ) ;

  for( $p = $Node; $p and $p->{Name} ne $Name or $p->{XMLClose} or $p->{End} ; $p=$p->{Prev} ) {} ;
  errorMsg( 0,"wrong close of $Name." ) and return undef unless $p ;

  if( $p and $p->{Next} )
  {
    $e           = $p->{Next} ;
    $p->{Next} = 0 ;
    $p->{FirstChild} = $e ;
    $p->{LastChild}  = $Node ;
    $e->{Prev} = 0 ;
    while( $e )
    {
      $e->{Parent} = $p ;
      $e = $e->{Next} ;
    }
  }
  else
  {
    $p = $Node ;
  }
  $p->{Text} = $p->{Trailer} ;
  $p->{End} = 1 ;
  $p->{Trailer} = $Tail ;
  return $p ;
}

sub ParamCount
{
  my $self = shift ;

  return( ref $self->{PCount} eq 'ARRAY' ? $self->{PCount}->[-1] : '' ) ;
}

sub _callwrap
{
  my( $Func,$Node,$AttrName,$Params ) = @_ ;
  my @FParams = ($Params =~ m/([^,'"](?:\\,|[^,])*|'(?:\\'|[^'])*'|"(?:\\"|[^"])*"|)\s*,?/sg) ;

  s/^\s*['"]?//s + s/['"]?\s*$//s foreach @FParams ;
  push @{$Node->{PCount}},scalar( @FParams ) ;
  return $uHTML::uAttr{$Func}( $Node,$AttrName,$Func,map((m/(?<!\\)\$(?=[a-zA-Z_])/s?codeAttr($Node,$AttrName,$_):$_),@FParams) ) if $uHTML::uAttr{$Func} ;
  errorMsg( 0,"unknown variable $Func.") ;
  return "\\\$$Func" ;
}

sub codeAttr
{
  my $Node  = shift ;
  my $Attr  = shift ;
  my $Value = shift ;

  return '' unless $Value or $Node->{Attributes} and ($Value = $Node->{Attributes}->{$Attr}) ne '' ;

  my( $func,$par,$tail,$sub,$rsub ) ;
  my @subs = split m/(?<!\\)\$(?=[a-zA-Z_\$])/s,$Value ;
  while( $#subs > 0 )
  {
    $rsub++ ;
    next unless $sub = pop @subs ;
    $sub =~ s/\\(?=\$)//s ;

    ( $func,$par,$tail ) = ($sub  =~ m/([a-zA-Z_][0-9a-zA-Z_]*)(?:\(\s*('(?:\\'|[^'])*'|"(?:\\"|[^"])*"|(?:\\.|[^()])*(?:\s*,(?:'(?:\\'|[^'])*'|"(?:\\"|[^"])*"|(?:\\.|[^()])))*)\s*\))?(.*)$/s) ;
    $sub = _callwrap( $func,$Node,$Attr,$par ) . $tail ;
    pop @{$Node->{PCount}} ;

    $subs[$#subs] .= $sub ;
  }
  $subs[0] =~ s/\\(?!\\)//sg ;

  return $subs[0] ;
}

sub attr
{
  my $Node  = shift ;
  my $Attr = shift ;
  my $Value = shift ;
  return( defined $Value ? rawAttr($Node,$Attr,$Value) : codeAttr($Node,$Attr) ) ;
}

sub errorMsg
{
  print STDERR "uHTML Error in $uHTML::FileName: $_[1]\n" if $_[2] or $uHTML::FileName ;
}

##########################################################
##########################################################
##########################################################

package uHTML;

local( $uHTML::Pos,@uHTML::Blocks,%uHTML::uHTML,%uHTML::uTag,%uHTML::uAttr,%uHTML::uSTag,$uHTML::FileName ) ;

sub _checkName
{
  my $Name = shift ;
  my $Code = shift ;

  $_->{$Name} and $_->{$Name} != $Code and return 0 foreach @_ ;
  return 1 ;
}

sub registerTagCode( $$ )
{
  my( $TagName,$Code ) = @_ ;

  push @{$uHTML::uCode{$TagName}},$Code if _checkName( $TagName,$Code ) ;
}

sub registerTag
{
  my( $TagName,$Code,$nowarn ) = @_ ;

  $uHTML::uTag{$TagName} = $Code if $nowarn or _checkName( $TagName,$Code,\%uHTML::uTag, \%uHTML::uSTag ) ;
}

sub registerAttrCode
{
  my( $AttrName,$Code,$nowarn ) = @_ ;

  registerVar( $AttrName,$Code ) if $nowarn or _checkName( $AttrName,$Code,\%uHTML::uAttr ) ;
}

sub registerVar
{
  my( $AttrName,$Code,$nowarn ) = @_ ;

  $uHTML::uAttr{$AttrName} = $Code if $nowarn or _checkName( $AttrName,$Code,\%uHTML::uAttr ) ;
}

sub register
{
  my( $Name,$Code,$nowarn ) = @_ ;

  $uHTML::uAttr{$Name} = $uHTML::uSTag{$Name} = $Code if $nowarn or _checkName( $Name,$Code,\%uHTML::uTag,\%uHTML::uAttr, \%uHTML::uSTag ) ;
}

sub tags()
{
  return ( keys %uHTML::uTag ) ;
}

sub testTag
{
  return( defined( $uHTML::uTag{$_[0]} ) or defined( $uHTML::uSTag{$_[0]} ) ? 1 : '' ) ;
}

sub vars()
{
  return ( keys %uHTML::uAttr ) ;
}

sub testVar
{
  return( defined( $uHTML::uAttr{$_[0]} ) || defined( $uHTML::uSTag{$_[0]} ) ? 1 : '' ) ;
}

sub fileStart
{
  return unless $uHTML::FileName and $_[0] ;
  push @uHTML::FNames,$uHTML::FileName ;
  $uHTML::FileName = $_[0] ;
}

sub fileEnd
{
  return $uHTML::FileName = pop @uHTML::FNames if $uHTML::FileName ;
}

sub _struct( $$$ )
{
  my( $Prev,$String,$env ) = @_ ;
  my( $Struct,$New,$val,$par,$tag ) ;

  if( ref $Prev eq 'uHTMLnode' )
  {
    if( $Prev->{Trailer} and $Prev->{Trailer} =~ m/([^<]*)(<.*)/s )
    {
      $String          = $2 . $String ;
      $Prev->{Trailer} = $1 ;
    }
    $Prev->{Trailer}  .= $1 if $String =~ m/^([^<]*)/sgc ;
  }
  else
  {
    $Prev = uHTMLnode->new( '',($String =~ m/^([^<]*)/sgc ? $1 : ''),undef,$env ) ;
  }
  $Struct = $Prev ;

  while( $tag = ($String =~ m/\G<(\/?[\w:-]+|[!?*])/sgc)[0] )
  {
    if( $tag =~ m/^\w[\w:-]*$/s )
    {
      my( %Attributes ) ;

      while( $String =~ m/\G\s*(\w[\w:-]*)\s*(?:\=\s*("(?:[^"]|\\")*(?<!\\)"|'(?:[^']|\\')*(?<!\\)'|[^\s>]+))?/sgc )
      {
        $par = $1 ;
        $val = $2 ;
        if( $par )
        {
          if( $val ne '' )
          {
            $val =~ s/^['"]|(?<!\\)\\|['"]$//sg ;
            $Attributes{$par} .= $val ;
          }
          else
          {
            $Attributes{$par} = undef unless exists $Attributes{$par} ;
          }
        }
      }
      lc $tag eq 'style' || lc $tag eq 'svg' || lc $tag eq 'script' && !exists $Attributes{'src'} ?
            $String =~ m/\G[^>]*?(\/)?>(.*?)(?=<\/$tag>)/sgci :
            $String =~ m/\G[^>]*?(\/)?>([^<]*)/sgc ;
      $New = uHTMLnode->new( $tag,$2,$Prev,$env ) ;
      $New->attributes( \%Attributes ) if %Attributes ;
      $New->XMLClose( $1 ) ;
    }
    elsif( $tag =~ m/^\/(\w[\w:-]*)$/s )
    {
      $tag = $1 ;
      $String =~ m/\G\s*\>([^<]*)/sgc ;
      $Prev = $Prev->_close( $tag,$1,"wrong close of $tag." ) if $Prev ;
      undef $New ;
    }
    elsif( $tag =~ m/^[!?]/ )
    {
      if( $tag eq '!' and $String =~ m/\G--/sgc )
      {
        $tag = '!--' ;
        $String =~ m/\G(.*?-->[^<]*)/sgc ;
        $val = $1 ;
      }
      else
      {
        $String =~ m/\G((?:[^'">]|"(?:[^"]|\\")*(?<!\\)"|'(?:[^']|\\')*(?<!\\)')*>[^<]*)/sgc ;
        $val = $1 ;
      }
      $New = uHTMLnode->new( '',"<$tag$val",$Prev,$env ) ;
    }
    elsif( $tag eq '*' )
    {
      $String =~ m/\G(.*?\*>[^<]*)/sgc ;
      $New = uHTMLnode->new( '',"<*$1",$Prev,$env ) ;
    }
    else
    {
      $String =~ m/\G([^<]*)/sgc ;
      $New = uHTMLnode->new( '',"$tag$1",$Prev,$env ) ;
    }
    if( $New )
    {
      $Prev->{Next}  = $New ;
      $Prev          = $Prev->{Next} ;
      undef $New ;
    }
  }

  $Prev->{Next} = uHTMLnode->new( '',$1,$Prev,$env ) if $String =~ m/\G(.+)/sg ;
  return $Struct ;

}

sub parse
{
  my( $data,$env ) = @_ ;

  $env = \%ENV unless ref $env eq 'HASH' ;
  return _struct( undef,$data,$env ) ;
}

sub recodedList( $$ )
{
  my( $uhtml,$env ) = @_ ;
  my( @HTML,$node,$T ) ;

  return undef if $uhtml eq '' ;

  if( $uhtml =~ m/</ )
  {
    loadModules( $env = \%ENV ) unless ref $env eq 'HASH' ;
    for( $T = $node = _struct( undef,$uhtml,$env ) ; $node ; $node = $node->{Next} ) { push @HTML,$node->process() }
  }
  else
  {
    $HTML[0] = $uhtml ;
  }
  return \@HTML ;
}

sub recode( $$ )
{
  my( $uhtml,$env ) = @_ ;
  return '' if $uhtml eq '' ;
  my $HTML = recodedList( $uhtml,$env ) ;
  return( wantarray ? @{$HTML} : join( '',@{$HTML} ) ) ;
}

######################################
######################################

sub loadModules( $ )
{
  my $env = shift ;

  return unless ref $env eq 'HASH' ;

  my $CPath ;

  unless( $CPath = $env->{'SCRIPT_ROOT'} )
  {
    $CPath = $0 =~ m%^/% ? $0 : $env->{'SCRIPT_FILENAME'} ;
    $CPath =~ s%/[^/]*$%%s ;
    $CPath = '.' unless $CPath ;
  }

  return unless opendir DH,$CPath ;
  require "$CPath/$_" foreach sort grep -f "$CPath/$_", grep m/-uHTML\.pmc?$/, readdir DH ;
  return unless opendir DH,"$CPath/uHTML" ;
  require "$CPath/uHTML/$_" foreach sort grep -f "$CPath/uHTML/$_", grep m/\.pmc?$/, readdir DH ;
}

1;

__END__


######################################
######################################

=pod

=encoding UTF-8

=head1 NAME

=over 2

=item B<uHTML> -  user specific extension of B<HTML> code

=for comment =item B<uHTMLnode> - central B<uHTML> data structure

=back

=head1 VERSION

Version 1.92

=head1 SYNOPSIS

A short example of a <include> tag using B<CGI> (and apache).
The function of the tag should be obvious.
The example consists of two files, a B<perl>-file and a B<uHTML>-file.
The B<perl>-file implements the tag which is then used in the B<uHTML>-file.

=head2 perl-file (CGI executable):
B< >

=over 3

  #!/usr/bin/perl

  use uHTML;

  sub Include($) {
    my $Node = shift;
    $Node->map(join('',<FH>),'') if $Node->attr('file') and
                                    open FH,$ENV{'DOCUMENT_ROOT'}.$Node->rawAttr('file');
  }

  uHTML::registerTag('include',\&Include);

  #hook
  open FILE,"$ENV{'DOCUMENT_ROOT'}$ENV{'PATH_INFO'}" or die "File: $ENV{'PATH_INFO'} not found";
  print "Content-type: text/html\n\n";
  print uHTML::recode(<FILE>);

=back

This perl file can be broken up into two files, separating the definition of the tag
from the cgi hook. By this the cgi hook S<C<open ... uHTML::recode>> can remain the same
for several projects, while the library file is added to the cgi directory according to the
requirement. Adequate named or located files are loaded automatic by the B<uHTML> module.
This allows to add html extensions according to a websites needs by copying of files
without the intervention of a programmer.

Usage of the <include> tag:

=head2 uHTML-file:
B< >

=over 3

  <html>
  ...
  <include file="/inc/headmetadata.txt">
  ...
  </html>

=back

=head1 DESCRIPTION
B< >

B<uHTML> allows to extend HTML with user defined tags, extend standard HTML tags with new
attributes and alter the behaviour of standard HTML tags and attributes. The server translates
uHTML on the fly into HTML similar to B<PHP> and other server side scripting languages. The main
advantage of uHTML is following the HTML syntax allowing webdesigners not familiar with programming
to use and edit uHTML tags in the same manner as HTML tags. Further uHTML makes copying of code
snippets across of project files superfluous simplifying maintenance and increasing the robustness
of code.

B<uHTML > consists of two packages, B<uHTML> itself and B<uHTMLnode> which provides the recursive
structure of a B<uHTML> document. While B<uHTML> is used to invoke the module, uHTMLnode
provides the interface to the customized tag code.

========================

=head1 package uHTML
B< >

The B<uHTML> package loads all modules from the script directory that match uHTML/*pm and
that match *-uHTML.pm. It provides methods that assign code to tags and to tag attributes
and invokes the B<uHTML> to B<HTML> translation.

=head2 Methods
B< >

    uHTML::registerTagCode( $TagName,$Code ) ;

Bind the function $Code to the tags named $TagName. The function $Code will be called with
a reference of the B<uHTML> node corresponding to the tag S<C<$Code( $Node )>>. The function
is expected to alter and adjust the tag attributes and content. The modified tag gets
automatically inserted into the B<HTML> output.

If more then one function is bound to one tag, the functions are daisy-chained.
The execution order of those functions is not determined.

    uHTML::registerTag( $TagName,$Code ) ;

Bind the function $Code to the tags named $TagName. The function $Code will be called with
a reference of the B<uHTML> node corresponding to the tag S<C<$Code( $Node )>>. The function
is expected to insert necessary data using the appropriate B<uHTMLnode> methods
S<C<$node-E<gt>map( $HeadText,$TailText )>> or S<C<$node-E<gt>insert()>>.

    uHTML::registerAttrCode( $VarName,$Code ) ;
    uHTML::registerVar( $VarName,$Code ) ;

Bind the function $Code to the attribute variable called $VarName.
Both functions are identical. The attribute variable gets replaced by the return
value of the function.

The function $Code is called with a reference to the node representing the tag,
the name of the attribute containing the function and the function name, followed
by the function arguments: S<C<$Code( $Node,$Attribute,$Function,$Value1,$Value2, ... )>>.

    uHTML::register( $Name,$Code ) ;

Bind the function $Code to the attribute variable called $Name and to a tag called $Name
simultaneously. The tag or attribute variable gets replaced by the return
value of the function.

The function $Code is called with a reference to the node representing the tag,
the name of the attribute containing the function and the function name, followed
by the function arguments: S<C<$Code( $Node,$Attribute,$Function,$Value1,$Value2, ... )>>.

If the function is called in reference to a tag, $Attribute and $Function are not defined.
In this case the function if necessary has to set the values $Value1, $Value2, ..., from
the attributes of the tag using S<C<$Node-E<gt>Attr( $Name )>>.

    uHTML::Tags() ;

Returns a list of all tags with a function assigned to.

    uHTML::TestTag( $Name )

Check if some code is bound to the tag $Name.

    uHTML::TestVar( $Name )

Check if some code is bound to the attribute variable $Name.

    uHTML::fileStart

Set the current file name for debug output. Ignored in production mode.

    uHTML::fileEnd

Reset the current file name for debug output to the previous name. Ignored in production mode.

    uHTML::parse( $text,$env ) ;

Parses $text into a B<uHTML> tree. Returns a reference to a B<uHTMLnode> node.
$env provides a reference to the environment. If not given, the current environment is used.

    uHTML::recoded_list( $uhtml,$env ) ;

Translates B<uHTML> data $uhtml into B<HTML>. Returns a reference to a array of B<HTML> chunks
containing the final B<HTML> code. $env provides a reference to the environment. If not given,
the current environment is used.

    uHTML::recode( $uhtml,$env ) = @_ ;

Translates B<uHTML> data $uhtml into B<HTML>. Depending on the context returns a scalar
or string array containing the final B<HTML> code. $env provides a reference to the environment. If not given,
the current environment is used.

=head3 B<Production Mode> and B<Debug Mode>

B<uHTML> produces some (sparse) error codes. It is advisable to switch them off in production mode.
At the same time B<HTML> comments get removed and the code get slightly compacted. The
production mode is activated with S<C<$uHTML::FileName = '' ;>> prior to translation of B<uHTML> to B<HTML>.

========================

=head1 package uHTMLnode
B< >

The package B<uHTMLnode> provides the hierarchical structure for the B<uHTML> code
and contains after the translation the B<HTML> data.

=head2 Data Structure
B< >

B<uHTMLnode> is only remotely related to the B<HTML> nodes in B<DOM>. The data structure is
intended to be manipulated only by its methods.

=over 6

=item # FirstChild:   -
first child node

=item # LastChild:    -
last child node

=item # Parent:       - parent node

=item # Prev:         - previous node (Null for the first node in a hierarchy level)

=item # Next:         - following node (Null for the last node in a hierarchy level)

=item # Name:         - name of the node (tag name)

=item # End:          - true if the node has a closing counterpart S<(e.g. E<lt>divE<gt> ... E<lt>/divE<gt>)>

=item # XMLClose:     - true if the node has no closing counterpart but is noted in XML
manner with a "/" before the closing bracket S<(e.g. E<lt>img ..... /E<gt>)>

=item # Attributes:   - reference to a HASH containing the attributes of a tag

=item # Text:         - text within a node till the first child node or end of the node
(corresponds to the first text node in B<DOM> if the first B<DOM> child node is a text node)

=item # Trailer:      - text following a node (corresponds in B<DOM> to the first text
node following the node if the first following node is a B<DOM> text node)

=item # tainted:      - recursive processing of the node necessary

=item # HTML:         - final B<HTML> code

=item # ENV:          - pointer to the current environment, decisive in B<FCGI> environments

=back



=head2 Methods
B< >

    uHTMLnode->new( $Name,$Text,$Prev,$env ) ;

Create a new node with the name $Name, a trailing text $Text and the preceding node $Prev.
This method is called by the B<uHTML> package and is seldom needed outside of it.

    $node->name() ;

The name of a node. It equals to the name of the B<uHTML> tag represented by the node.
By passing a argument S<C<$node-E<gt>Name($NewName)>> the tag can be renamed.

    $node->parent() ;

The parent node.

    $node->prev() ;

The preceding node.

    $node->next() ;

The following node.

    $node->copy() ;

Copies a node. This function is useful to generate lists. The copy of the node is not
hooked into the structure of the original B<uHTML> file, although the parent node is
correctly assigned. All child nodes are copied as well. The trailing text of the node
is not included in the copy.

    $node->prepend( $Node ) ;

Insert a node into the B<uHTML> tree before current node.

    $node->append( $Node ) ;

Insert a node into the B<uHTML> tree after current node.

    $node->embed( $Name ) ;

Creates a new node $Name and embeds the current node in it. In effect the current node
gets replaced by the new node $Name while the current node becomes the only child
of the new node.

    $node->firstChild() ;

First subordinated node.

    $node->lastChild() ;

Last subordinated node.

    $node->addChild( $Child,$PrevChild ) ;

Add a child node after the child node $PrevChild. If $PrevChild is not defined,
add as new first child node, if $PrevChild equals $node->lastChild() the new node
becomes the new last child.

The node $Child mustn't be a child of $node. If $Child has its parent node set, it
will be correctly moved within the B<uHTML> document.

    $node->appendChild( $Child ) ;

Add a child node as new last child.

The node $Child mustn't be a child of $node. If $Child has its parent node set, it
will be correctly moved within the B<uHTML> document.

    $node->adoptChildren( $From,$Child ) ;

Transfer the children of one node to another.

The children of the node $From are moved to the $node and inserted if $Child is given
after $Child or ahead of all children of $node if $Child is not defined.

    $node->findChild( $Name,$Child ) ;

Find a child node of $node named $Name after the child $Child. If $Child is undefined,
find first child node named $Name.

    $node->replace( $New,$KeepTrailer ) ;

Replaces a node in the B<uHTML> structure. Normally the trailing text gets replaced
in process too. To keep it, $KeepTrailer must be true. Returns the detached original
node if successful.

    $node->detach( $KeepTrailer ) ;

Detaches a node from the B<uHTML> structure. Normally the trailing text gets deleted
in process. To keep it, $KeepTrailer must be true.

    $node->delete() ;

Deletes a node from the B<uHTML> structure.

    $node->attr( $Name ) ;

The value of a singular attribute as a string. Possible attribute functions get interpreted.
If more then one attribute with the same name exist, the values are concatenated. If a value get provided
S<($node-E<gt>Attr( $Name,$Value ) ;)>, the attribute get set to this value. If the attribute do not exists,
it gets created.

    $node->rawAttr( $Name ) ;

The original value of a singular attribute as a string. Possible attribute functions are not interpreted.
If more then one attribute with the same name exist, the values are concatenated. If a value get provided
S<($node-E<gt>RawAttr( $Name,$Value ) ;)>, the attribute get set to this value. If the attribute do not exists,
it gets created.

    $node->codeAttr( $Name ) ;

The value of a singular attribute as a string. Possible attribute functions get interpreted.
If more then one attribute with the same name exist, the values are concatenated.

    $node->setAttr( $Name,$Value ) ;

Sets the attribute $Name to the $Value. If the attribute do not exists, it gets created.

    $node->testAttr( $Name ) ;

Tests the existence of the attribute $Name. This is necessary to test for attributes without
any value provided.

    $node->testAnyAttr( $Name1,$Name2,$Name3, ,... ) ;

Tests the existence of any of the attributes with the provided names.

    $node->testAllAttr( $Name1,$Name2,$Name3, ,... ) ;

Tests the existence of all attributes with the provided names.

    $node->addAttr( $Name1,$Name2,$Name3, ,... ) ;

Creates the attributes $Name1, $Name2, $Name3, ,..., without assigning a value to them.

    $node->deleteAttr( $Name1,$Name2,$Name3, ,... ) ;

Deletes the attributes $Name1, $Name2, $Name3, ,...

    $node->attributes()

Reference to the attributes of a node. E.g. the style of a tag can be accessed by $node->attributes()->{'style'}.
The methods above which access single attributes should be preferred.

    $node->text() ;

The text inside of a closed tag up to the first child tag. It corresponds to the first text node
in B<DOM> if the first B<DOM> child node is a text node. Can be altered by passing a argument.

    $node->trailer() ;

The text following a tag up to the next tag. It corresponds in B<DOM> to the first text
node following the node if the first following node is a B<DOM> text node.
Can be altered by passing a argument.

    $node->end() ;

True, if a tag is closed (the closing tag exists). If a argument is passed,
the node becomes a closed node or open node depending on the argument.

    $node->XMLClose() ;

True if the tag is closed by a "/>" instead of a simple ">". Can be enforced
or removed by passing an according argument.

    $node->map( $HeadText,$TailText ) ;

Map a node into B<HTML> output without tags preceding the node with $HeadText and closing it
with $TailText. If a node has no closing tag, $TailText follows directly $HeadText.
Practically seen it replaces the opening and closing tags with $HeadText and $TailText.
This is the most common way to produce B<HTML> output in functions hooked into
B<uHTML> using S<C<uHTML::registerTag( $TagName,$Code ) ;>>.

    $node->insert() ;

Inserts a node's B<HTML> code including the tags and attributes. It is meant to insert
an altered node into the B<HTML> output. This is the second way to produce B<HTML> output
in functions hooked into B<uHTML> using S<C<uHTML::registerTag( $TagName,$Code ) ;>>.

    $node->HTML() ;

The B<HTML> code of a node after a map() or insert() was performed. It is empty before
a map() or insert() on the node is done. It is possible to set this value
directly by passing an argument S<C<$node-E<gt>HTML( $html )>>.
By setting it the resulting B<HTML> code is replaced by $html.

    $node->appendText( $text ) ;

Append $text to the existing B<HTML> output.

    $node->env() ;

Returns a reference to the current environment in which a B<HTTP> request
is performed.


=head1 TODO

Port it to other languages. Make it faster.

=head1 BACKGROUND

While exploring problems connected to the integration of dynamic content into
html documents in projects maintained by several people, it became apparent
that any mixture of program and html code
leads to charge conflicts between programmers and designers.

Extending and customizing html according to the requirements of a project
while maintaining the familiar html syntax allows the html designer easy
access to custom functions of a website. It leads to abatement of conflicts, errors,
increases the readability of html documents and decreases the development time.
The effect is specially reflected while the maintenance of a project where design
improvements usually do not imply any action of the programmer and are sole done by the
designer.

On the programmers side a consistent interface to the html tags leads to similar effects.
uHTML == user-HTML connects basically each html tag with a code chunk allowing a manipulation
of the html code before it leaves the http server. The strict assignment of functions to tags
allows a high reusability of code. Indeed a set of customized tags can be included
into a project by simply copying of the correlated module file into the project directory.


=head1 SEE ALSO

perl(1), httpd(8), http://www.uhtml.de/en/doc/uHTML.uhtml

=head1 AUTHOR

Roland Mosler (Roland.Mosler@Place.Ug)

=head1 COPYRIGHT

Copyright 2009 Roland Mosler.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
