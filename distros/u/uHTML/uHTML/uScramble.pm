


#
# Author: Roland Mosler - Roland@Place.Ug
#
# Das ist eine uHTML-Bibliothek von Place.Ug
# Es ist erlaubt dieses Paket unter der GPLv3 zu nutzen
# Bei Weiterentwicklungen ist die Ursprungsbibliothek zu nennen
#
# Fehler und Verbesserungen bitte an uHTML@Place.Ug
#
# This is a uHTML library from Place.Ug
# It is allowed to use this library under the GPLv3
# The name of this library is to be named in all derivations
#
# Please report errors to uHTML@Place.Ug
#
# © Roland Mosler, Place.Ug
#



use strict ;

package uHTML::uScramble ;

use version ; our $VERSION = "0.95" ;

use uHTML ;

sub _GetGlobVal
{
  my $env = shift ;
  $env->{'uScramble.GlobVal'} = int rand 2147483647 unless $env->{'uScramble.GlobVal'} ;
  return $env->{'uScramble.GlobVal'} ;
}

sub fak
{
  my $n = @_ ;
  my $r = $n-- ;
  $r *= $n-- while $n > 1 ;
  return $r
}

sub permutate
{
  my( $N,@S ) = @_ ;
  my( $l,$i,@P ) ;

  for( $i=$#S; $i>=0; $i-- )
  {
    $l     = $N % ($i+1) ;
    $N     = int($N/($i+1)) ;
    $P[$i] = $S[$l] ;
    $S[$l] = $S[$i] ;
  }
  return @P ;
}

sub upermutate
{
  my( $N,@S ) = @_ ;
  my( @P ) ;
  my @Per = permutate( $N,( 0 .. $#S ) ) ;

  $P[$Per[$_]] = $S[$_] foreach( 0 .. $#S ) ;
  return @P ;
}


sub GlobCode
{
  return _GetGlobVal( $_[0]->{'ENV'} ) ;
}

### scrambling of short strings not good yet

sub _Scramble
{
  my $GlobVal = shift ;
  my( $R,$C,$c,$B,$b,$L,$S ) ;

  $S = $_[0] =~ s/(\W)/sprintf( ':%02X',ord $1 )/egsr ;

  if( ($L = length $S) > 14 )
  {
    for( $b=14; $b>4; $b-- )
    {
      if( $c = $L % $b ) { $C = $c, $B = $b if $c > $C }
      else               { $C = 0,  $B = $b ; last }
    }
    $C  = int( $L/$B ) + ($C ? 1 : 0) ;
  }
  else
  {
    $B = $L ; $C = 1 ;
  }

  my $code = 12323 | int rand( $B > 12 ? 2147483647 : fak( $B )-1 ) ;
  for( $c=0; $c<$C; $c++ )
  {
    $R .= join( '',permutate( $code,split( //,substr( $S,$c*$B,$B ) ) ) ) ;
  }
  return join( '*',$code^$GlobVal,$B,$C,$R ) ;
}

sub _setID
{
  my $Node = shift ;
  my $env  = $Node->{'ENV'} ;
  $Node->setAttr( 'id','scramble' . ++$env->{'uScramble.Count'} ) unless $Node->testAttr( 'id' ) ;
}

sub ScrambleText
{
  my $Node = shift ;
  my $env  = $Node->{'ENV'} ;
  return unless $Node->end() ;
  $Node->name( $Node->testAttr( 'tag' ) ? $Node->attr( 'tag' ) : 'span' ) ;
  $Node->deleteAttr( 'tag' ) ;
  _setID( $Node ) ;
  push @{$env->{'uScramble.Coded'}->{ $Node->attr( 'id' ) }},'#' ;
  my $text = _Scramble( _GetGlobVal( $env ),join( '',@{$Node->map( '','' )} ) ) ;
  $Node->insert( $text ) ;
}

sub ScrambleAttr
{
  my( $Node,$Par,$Var,$Text ) = @_ ;
  my $env  = $Node->{'ENV'} ;
  my $Attr = $Node->rawAttr( $Par ) ;
  my $H ;

  _setID( $Node ) ;
  $H++ while $Attr =~ m/\[\}$H\{\]/ ;
  $H = "[}$H\{]" ;
  push @{$env->{'uScramble.Coded'}->{ $Node->attr( 'id' ) }},"$H$Par" ;
  return( $H . _Scramble( _GetGlobVal( $env ),$Text ) . $H ) ;
}

sub ScJavaScriptData
{
  my $Node = shift ;
  my $env  = $Node->{'ENV'} ;

  return unless $env->{'uScramble.Count'} > 0 ;

  my ( $Text,$id,$par,$GV,$T,$A ) ;

  $GV = _GetGlobVal( $env ) ;
  foreach $id( keys %{$env->{'uScramble.Coded'}} )
  {
    foreach $par( @{$env->{'uScramble.Coded'}->{$id}} )
    {
      $Text .= ($par eq '#') ?
                  ++$T && "deScrambleText( document.getElementById(\"$id\") ) ;\n" :
                  ++$A && "deScrambleAttr( document.getElementById(\"$id\"),\"$par\" ) ;\n" ;
    }
  }

  $A = ! $A ? "" : "function deScrambleAttr( elem,param )
  {
    var D = param.match( /^\\[\\}\\d*\\{\\]/ ) ;
    var P = param.replace( /^\\[\\}\\d*\{\\]/,\"\" ) ;
    var A = elem.getAttribute( P ) ;

    if( A )
    {
      var V = elem.getAttribute( P ).split( D[0] ) ;
      V[1] = deScrambleString( V[1] ) ;
      elem.setAttribute( P,V.join(\"\") ) ;
    }
  }" ;

  $T = !$T ? "" : " function deScrambleText( elem )
  {
    elem.innerHTML = deScrambleString( elem.innerHTML ) ;
  }" ;

  $Node->map( "
  <script>

  var GlobCodeVal = $GV ;

  function permutate( N,S )
  {
    var l,i,P = new Array ;

    for( i=S.length-1; i>=0; i-- )
    {
      l     = N % (i+1) ;
      N     = Math.floor(N/(i+1)) ;
      P[i] = S[l] ;
      S[l] = S[i] ;
    }
    return P ;
  }

  function upermutate( N,S )
  {
    var P   = new Array ;
    var Per = new Array ;
    var Num = new Array ;
    var i ;

    for( i=S.length-1; i>=0; i-- ) Num[i] = i ;
    Per = permutate( N,Num ) ;

    for( i=S.length-1; i>=0; i-- ) P[Per[i]] = S[i] ;
    return P ;
  }

  function deScrambleString( S )
  {
    var i,R,B,c ;
    var D = S.split(\"*\") ;
    if( D[0].match( /\\D/ ) ) return S ;
    c = parseInt(D[0])^GlobCodeVal ;
    R = \"\" ;
    for( i=0; i<D[2]; i++ )
    {
      B  = D[3].substr( i*D[1],D[1] ) ;
      R += upermutate( c,B.split('') ).join('') ;
    }
    return decodeURIComponent( R.replace( /\\:(..)/g,\"%\$1\") ) ;
  }

  $T
  $A
  $Text

  </script>
  ",'' ) ;
}

sub GetScBody
{
  my $Body = shift ;
  my $env  = $Body->{'ENV'} ;

  return if exists $env->{'uScramble.Code'} and not $Body->testAttr( 'scramble' ) ;
  $env->{'uScramble.Code'} = uHTMLnode->new( 'ScrambleJSData','',undef,$env ) ;
  $Body->appendChild( $env->{'uScramble.Code'} ) ;
  $Body->deleteAttr( 'scramble' ) ;
}

uHTML::registerTag( 'Scramble',\&ScrambleText ) ;
uHTML::registerVar( 'Scramble',\&ScrambleAttr ) ;
uHTML::register( 'ScrambleCode',\&GlobCode ) ;
uHTML::registerTagCode( 'body',\&GetScBody ) ;
uHTML::registerTag( 'ScrambleJSData',\&ScJavaScriptData ) ;


######################################
######################################

=pod

=encoding UTF-8

=head1 NAME

=over 2

=item B<uHTML::uScramble> - Scrambling B<HTML> code

=back

=head1 VERSION

Version 0.95

=head1 DESCRIPTION

The library B<uHTML::uScramble> provides tags and functions to scramble the HTML output.
The scrambled HTML code get descrambled in the browser by a JavaScript function after loading.
As robots, scanners, crawler, etc. (usually) do not execute JavaScript within the loaded B<HTML>
pages, it is a simple method to conceal sensitive data, e.g. email addresses, from them.


Requirements

The B<uHTML::uScramble> library requires only the main B<uHTML> library.


B< >

=head1 B<uHTML> tags provided by the uHTML::uScramble library

B< >



=head2 Scramble

=head3 Overview


The Scramble tag scrambles its content before sending it to the browser. When selecting content for scrambling please take in account, that this content gets hidden from crawlers and can't get found by e.g. google.

Attributes

=head4 tag="name"

The attribute tag determines the name of the tag with which will replace Scramble. If missing it defaults to span.

=head3 Example

<Scramble tag="div">John@mail.com</Scramble>

=head2 ScrambleCode

=head3 Overview


The ScrambleCode tag inserts the actually used scramble code number. Is seldom used beyond debug purposes.


=head3 Example

<ScrambleCode>

B< >

=head1 Attribute variables and functions provided by the uHTML::Scramble library

B< >

=head2 $Scramble(text)

=head3 Overview


The Scramble function returns scrambles the content of an attribute.

=head3 Parameters

=head4 text

The parameter text defines the text to get obscured.

=head3 Example

<div title="$Scramble(John@mail.com)"> ... </div>

=head2 $ScrambleCode(B<>)

=head3 Overview


The ScrambleCode function returns the actually used scramble code number. Is seldom used beyond debug purposes.


=head3 Example

<Scramble title="$ScrambleCode"> ... </Scramble>



