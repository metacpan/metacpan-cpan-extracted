

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

package uHTML::std ;

use version ; our $VERSION = "2.26" ;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( uFilePath ) ;

use uHTML ;
use uHTML::ListFuncs( 'uniq','section','difference','shuffle' ) ;

my( %MACROS,$DEBUG,$DEBUG_MASK ) ;

my $SO = qr/\s*,\s*/ ;
my $RO = qr/\s*[,;:]\s*/ ;

use constant { TIMEOUT => 6000 } ;

sub setDebug
{
  $DEBUG      = shift ;
  $DEBUG_MASK = shift ;
}

sub DoIf( $ )
{
  my $Node = shift ;

  my $Child ;

  if( eval( $Node->attr( 'cond' ) ) )
  {
    my @D ;

    for( $Child=$Node->{'FirstChild'}; $Child; $Child=$Child->{'Next'} )
    {
      push @D,$Child if $Child->{'Name'} eq 'else';
    }
    $_->delete() foreach @D ;
    $Node->map( '','' ) ;
  }
  else
  {
    my( $Elif,$Else ) ;

    for( $Child=$Node->{'FirstChild'}; $Child && !$Elif; $Child=$Child->{'Next'} )
    {
      next unless $Child->{'Name'} eq 'else' ;

      if( $Child->testAttr( 'cond' ) )
      {
        $Elif = $Child if eval( $Child->attr( 'cond' ) ) ;
      }
      else
      {
        $Else = $Child ;
      }
    }
    $Else = $Elif if $Elif ;
    $Node->{'Text'} = '' ;
    $Node->{'HTML'} = $Else ? $Else->map( '','' ) : undef ;
  }
}

sub Choice( $ )
{
  my $Node = shift ;
  return unless $Node->testAttr( 'tag' ) ;
  my $Name = $Node->attr( 'tag' ) ;
  return unless $Name ;
  my $cond = eval( $Node->attr( 'cond' ) ) ? 0 : 1 ;
  my( $P,@S ) ;
  @S = split m/\|/,$Name,2 ;
  $Name = $S[$cond] if $#S>0 ;
  return unless $Name and $Name ne 'choice' ;
  $Node->name( $Name ) ;
  my $Add  = $Node->attr( 'attr' ) ;
  $Node->deleteAttr( 'cond','tag','attr' ) ;
  foreach( keys %{$Node->attributes()} )
  {
    next unless $P = $Node->rawAttr( $_ ) ;
    @S = split m/\|/,$P,2 ;
    $S[$cond] ne '' ? $Node->rawAttr( $_,$S[$cond] ) : $Node->deleteAttr( $_ ) if $#S>0 ;
  }
  if( $Add )
  {
    @S = split m/\|/,$Add,2 ;
    $Node->addAttr( split $SO,( $#S>0?$S[$cond]:$Add ) ) ;
  }
  $Node->process() ;     #kein insert da dann uHTML-Tags nicht berücksichtigt werden
  $Node->trailer( '' ) ; #process hat den Anhang bereits angefügt
}

sub VarChoice( $ )
{
  my( $Node,$Par,$Var,$cond,$true,$false ) = @_ ;
  return( eval $cond ? $true : $false ) ;
}

sub CondAttr
{
  my $Node = shift ;
  my $Name = $Node->attr( 'tag' ) ;

  return unless $Name ;
  $Node->name( $Name ) ;
  $Node->deleteAttr( 'tag' ) ;
  $Node->attr( $_ ) ne '' or $Node->deleteAttr( $_ ) foreach keys %{$Node->attributes()} ;
  $Node->map( '','' ) ;
}

sub Identity( $ )
{
  my $Node = shift ;

  return $_[1] if shift ;
  $Node->map( '','' ) ;
}

sub InsertText( $ )
{
  my $Node = shift ;

  return uHTML::recode( $_[1],$Node->{'ENV'} ) if shift ;
  $Node->testAttr( 'raw' ) ? $Node->HTML( $Node->attr( 'text' ) ) : $Node->map( $Node->attr( 'text' ),'' ) ;
}

sub ReplaceText
{
  my( $Node,$Par,$Var,$Text,$Pattern,$Replace,$opt ) = @_ ;

  unless( $Par )
  {
    $Text    = $Node->attr( 'text' ) ;
    $Pattern = $Node->attr( 'pattern' ) ;
    $Replace = $Node->attr( 'replace' ) ;
    $opt     = $Node->attr( 'options' ) ;
  }
  $Pattern =~ s"(?<!\\)/"\\/"g ;
  $Replace =~ s"(?<!\\)/"\\/"g ;
  $opt     =~ s"[^msixpgcadlu]""g ;
  eval( "\$Text =~ s/$Pattern/$Replace/$opt" ) ;
  return $Text ;
}

sub uFilePath( $$ )
{
  my( $IFile,$env ) = @_ ;
  $env = \%ENV unless ref $env eq 'HASH' ;

  return( $IFile=~s/^#// ? ( $env->{'DATA_ROOT'} && $IFile !~ m%^/% ? "$env->{'DATA_ROOT'}/$IFile" : $IFile ) :
                           ( $env->{'DOCUMENT_ROOT'}.(($IFile=~m%^/%) ? '' : ($env->{'PATH_INFO'}=~m%^(.*/)[^/]*$%)[0] ). $IFile ) ) ;
}

sub getFilePath
{
  return uFilePath( $_[1] ? $_[3] : $_[0]->attr('path'),$_[0]->env() ) ;
}

sub Include( $ )
{
  my $Node  = shift ;
  my $env   = $Node->{'ENV'} ;

  return if $Node->testAttr( 'cond' ) and not eval( $Node->attr( 'cond' ) ) ;

  my( $FH,$FN,$IFile,@Files,@Text ) ;

  push @Files,$IFile if $Node->testAttr( 'file' ) and $IFile = uFilePath( $Node->attr( 'file' ),$env ) and -f $IFile ;
  push @Files,grep -f,glob( uFilePath( $IFile,$env ) ) if $Node->testAttr( 'files' ) and $IFile = $Node->attr( 'files' ) ;
  @Files = grep -f,glob( uFilePath( $IFile,$env ) )    if not @Files and $IFile = $Node->attr( 'alt' ) ;

  print STDERR "Include looks for $IFile (".$Node->attr( 'file' ).")\n" if $DEBUG > 1 ;

  if( @Files )
  {
    foreach $FN( @Files )
    {
      if( -f $FN and open $FH,$FN )
      {
        local $_ ;

        print STDERR "include $FN\n" if $DEBUG > 0 ;

        if( $Node->testAttr( 'raw' ) )
        {
          push @Text,<$FH> ;
        }
        else
        {
          my( $FT,$HT ) ;

          uHTML::fileStart( $FN ) ;
          read $FH,$FT,-s $FH ;
          $HT = uHTML::recodedList( $FT,$env ) ;
          push @Text,@{$HT} ;


          uHTML::fileEnd() ;
        }
      }
      else
      {
        $Node->errorMsg( "Include: File \"$FN\" not readable." ) if $Node->testAttr( 'warn' ) ;
      }
    }
    $Node->HTML( @Text ) ;
  }
  else
  {
    $Node->errorMsg( "Include: File \"$IFile\" not found." ) if $Node->testAttr( 'warn' ) ;
  }
}

sub VarInclude()
{
  my( $Node,$Par,$Var,$IFile,$alt,$raw ) = @_ ;
  return '' unless $IFile ;

  my( $FH,$FN,@Files,@Text ) ;
  my $env   = $Node->{'ENV'} ;

  if( @Files = grep -f,glob( uFilePath( $IFile,$env ) ) )
  {
    foreach $FN( @Files )
    {
      if( -f $FN and open $FH,$FN )
      {
        local $_ ;

        if( $raw )
        {
          push @Text,<$FH> ;
        }
        else
        {
          my( $FT,$HT ) ;

          uHTML::fileStart( $FN ) ;
          read $FH,$FT,-s $FH ;
          $HT = uHTML::recodedList( $FT,$env ) ;
          push @Text,@{$HT} ;
          uHTML::fileEnd() ;
        }
      }
    }
    return join( '',@Text ) ;
  }

  return $alt ;

}


sub _getDefine( $$ )
{
  my( $env,$Name ) = @_ ;

  return $env->{'uHTML.Defines'}->{$Name} if ref $env->{'uHTML.Defines'} eq 'HASH' ;

  my %Defines ;
  $env->{'uHTML.Defines'} = \%Defines ;
  return undef ;
}

sub _testDefine( $$ )
{
  my $D = _getDefine( $_[0],$_[1] ) ;
  return( ref $D eq 'ARRAY' and @{$D} and $D->[0] ne '' ) ;
}

sub _Replace( $$$ )
{
  my( $Node,$Par,$Var ) = @_ ;
  $Var = $Node->name() unless $Par ;
  my $D = _getDefine( $Node->{'ENV'},$Var ) ;


  print STDERR "Insert $Var = '$D->[0]'  ($Node->{'ENV'}, $Node->{'ENV'}->{'uHTML.Defines'})\n" if $DEBUG > 1 and ref $D ;
  print STDERR "Insert $Var = '${$Node->{'ENV'}->{'uHTML.Defines'}->{$Var}}[0]'\n" if $DEBUG > 1 and ref $D eq 'ARRAY' ;
  print STDERR "Insert $Var = ''\n" if $DEBUG > 1 and ref $D ne 'ARRAY' ;

  return( ref $D eq 'ARRAY' ? join '',uHTML::recode( $D->[0],$Node->{'ENV'} ) : '' ) ;
}

sub Define( $ )
{
  my $Node = shift ;
  my $env  = $Node->{'ENV'} ;
  my $def ;

  return unless $Node->attributes() ;
  if( $Node->testAttr( 'createonly' ) and not $Node->rawAttr( 'createonly' ) )
  {
    foreach $def( keys %{$Node->attributes()} )
    {
      next if $def eq 'createonly' or _testDefine( $env,$def ) ;
      uHTML::register( $def,\&_Replace,1 ) ;
      $env->{'uHTML.Defines'}->{$def}->[0] = $Node->attr( $def ) ;
      print STDERR "Unique Define $def\=$env->{'uHTML.Defines'}->{$def}->[0]\n" if $DEBUG > 0 ;
    }
  }
  elsif( $Node->testAttr( 'replace' ) and not $Node->rawAttr( 'replace' ) )
  {
    foreach $def( keys %{$Node->attributes()} )
    {
      next if $def eq 'replace' ;
      uHTML::register( $def,\&_Replace,1 ) unless _testDefine( $env,$def ) ;
      $env->{'uHTML.Defines'}->{$def}->[0] = $Node->attr( $def ) ;
      print STDERR "Replace Define $def\=$env->{'uHTML.Defines'}->{$def}->[0]\n" if $DEBUG > 0 ;
    }
  }
  else
  {
    foreach $def( keys %{$Node->attributes()} )
    {
      my $v = $Node->codeAttr( $def ) ;
      uHTML::register( $def,\&_Replace,1 ) unless _testDefine( $env,$def ) ;
      unshift @{$env->{'uHTML.Defines'}->{$def}},$Node->attr( $def ) ;
      print STDERR "Define $def\=$env->{'uHTML.Defines'}->{$def}->[0]\n" if $DEBUG > 0 ;
    }
  }
}

sub ClearDef( $ )
{
  my $Node = shift ;

  return unless $Node->attributes() ;
    print STDERR "Undef ${\(join ',',keys %{$Node->attributes()})}\n" if $DEBUG > 0 ;
  foreach( keys %{$Node->attributes()} )
  {
    my $D = _getDefine( $Node->{'ENV'},$_ ) ;
    next unless ref $D eq 'ARRAY' and @{$D} ;
    shift @{$D} ;
    uHTML::register( $_,undef,1 ) unless @{$D} ;
    print STDERR "Undef $_\n" if $DEBUG > 1 ;
  }
}

sub Alternative
{
  my $Node = shift ;
  my $Par  = shift ;
  my $Var  = shift ;
  my $Cnt  = $Node->ParamCount() ;
  my $Val ;

  $Val = shift and return $Val while $Cnt-- ;

  return '' ;
}

sub AltText
{
  my $Node = shift ;
  my $Par  = shift ;
  my $Var  = shift ;
  my $Cnt  = $Node->ParamCount() ;
  my $Val ;

  ($Val = shift) ne '' and return $Val while $Cnt-- ;

  return '' ;
}

sub _checkMacro( $$ )
{
  my( $env,$Name ) = @_ ;

  return undef unless $Name and ref $env eq 'HASH' ;

  if( ref $env->{'uHTML.Macros'} ne 'HASH' )
  {
#

      my( %Macros,%MacroVal,%MacroHTML,%MacroBody ) ;
    $env->{'uHTML.Macros'}    = \%Macros ;   #$MACROS{$env->{'HTTP_HOST'}}->{'Macros'} ;
    $env->{'uHTML.MacroVal'}  = \%MacroVal ; #$MACROS{$env->{'HTTP_HOST'}}->{'MacroVal'} ;
    $env->{'uHTML.MacroHTML'} = \%MacroHTML ;#$MACROS{$env->{'HTTP_HOST'}}->{'MacroHTML'} ;
    $env->{'uHTML.MacroBody'} = \%MacroBody ;#$MACROS{$env->{'HTTP_HOST'}}->{'MacroBody'} ;
  }


  return $env->{'uHTML.Macros'}->{$Name} ;
}

sub _getMacroValue()
{
  my $Node = shift ;
  my $Par  = shift ;
  my $Name = shift ;
  my $Cnt  = scalar @_ ;
  my $env  = $Node->{'ENV'} ;
  my $M    = _checkMacro( $env,$Name ) ;

  print STDERR "getMacroValue $Name (".ref($M).")\n" if $DEBUG > 0 ;
  return '' unless $M and ref $M eq 'uHTMLnode' ;
  return $env->{'uHTML.MacroHTML'}->{$Name} if exists $env->{'uHTML.MacroHTML'}->{$Name} ;
  my $Macro = $M->copy ;
  if( $Cnt and ref $env->{'uHTML.MacroAttr'}->{$Name} eq 'ARRAY' )
  {
    my( $attr,$val ) ;
    $env->{'uHTML.MacroVal'}->{$Name}->{$a} = $b ;
    foreach $attr( @{$env->{'uHTML.MacroAttr'}->{$Name}} )
    {
      $val = $Cnt-- > 0 ? shift : $env->{'uHTML.MacroVal'}->{$Name}->{$attr} ;
      uHTML::register( $attr,\&_Replace,1 ) unless _testDefine( $env,$attr ) ;
      unshift @{$env->{'uHTML.Defines'}->{$attr}},$val ;
    }
    $Macro->map( '','' ) ;
    shift @{$env->{'uHTML.Defines'}->{$_}} foreach @{$env->{'uHTML.MacroAttr'}->{$Name}} ;
  }
  else
  {
    $Macro->map( '','' ) ;
  }
  return( $env->{'uHTML.MacroHTML'}->{$Name} = $Macro->HTML() ) ;
}

sub _DoMacro( $ )
{
  my $Node = shift ;
  my $env  = $Node->{'ENV'} ;
  my $Name = $Node->name() ;
  my $Macro ;

  print STDERR "Check Macro '$Name'\n" if $DEBUG > 1 ;
  return unless my $M = _checkMacro( $env,$Name ) ;
  print STDERR "Execute Macro '$Name'\n" if $DEBUG > 0 ;

    $Node->map( '','' ) if $env->{'uHTML.MacroBody'}->{$Name} ;   # needed only if MacroBody is present
    $Macro = $M->copy() ;

    foreach( keys %{$env->{'uHTML.MacroVal'}->{$Name}} ) { $Node->setAttr( $_,$env->{'uHTML.MacroVal'}->{$Name}->{$_} ) unless $Node->testAttr( $_ ) }
    $Node->deleteAttr( 'createonly','replace' ) ;
    print STDERR "Execute macro $Name(${\(join ',',map \"$_='${\($Node->attr($_))}'\",keys %{$Node->attributes()})})\n" if $DEBUG > 0 ;
    Define( $Node ) ;
    $Macro->map( '','' ) ;
    ClearDef( $Node ) ;



#   else

  if( $env->{'uHTML.MacroBody'}->{$Name} )
  {
    my( $H,$T ) = split m/<MacroBody>/s,$Macro->HTML(),2 ;
    $T =~ s/<MacroBody>//sg ;
    $Node->HTML( $H . $Node->HTML() . $T ) ;
  }
  else
  {
    $Node->HTML( $Macro->HTML() ) ;
#     $Node->HTML( $Macro->HTML() . $Node->HTML() ) ;  # Orig Version !!!!!
  }
}

sub _findMacroBody
{
  my $Node = shift ;

  return undef unless $Node->firstChild() ;

  my( $Child,$Body ) ;

  for( $Child = $Node->firstChild() ; $Child ; $Child=$Child->next() )
  {
    return $Child if $Child->name() eq 'MacroBody' ;
    return $Body  if $Body = _findMacroBody( $Child ) ;
  }
  return undef ;
}

sub Macro( $ )
{
  my $Node = shift ;
  my $env  = $Node->{'ENV'} ;
  my $Replace ;
  my $Name ;

  return unless $Node->end() and $Name = $Node->attr( 'name' ) ;
  return if     $Replace = _checkMacro( $env,$Name ) and not $Node->testAttr( 'replace' ) ;
  print STDERR "Define Macro '$Name\(${\($Node->attr( 'attributes' ))}\)'\n" if $DEBUG > 0 ;
  $env->{'uHTML.MacroBody'}->{$Name} = _findMacroBody( $env->{'uHTML.Macros'}->{$Name} = $Node ) ;
  if( $Node->testAttr( 'attributes' ) )
  {
    my( $a,$b,$t,$v,@A ) ;
    my @AT = split $SO,$Node->attr( 'attributes' ) ;
    while( @AT )
    {
      $b = '' ;
      $v = shift @AT ;
      ( $a,$b ) = ($v =~ m/([^\=\s]+)(?:\s*\=\s*(\S.*))?/) ;
      if( $b and $b =~ s/^(["'])// )
      {
        $t = $1 ;
        $b .= shift @AT unless $b =~ s/$t$// or not @AT ;
      }
      $env->{'uHTML.MacroVal'}->{$Name}->{$a} = $b ;
      push @A,$a ;
    }
    $env->{'uHTML.MacroAttr'}->{$Name} = \@A ;
  }
  return if $Replace ;
  uHTML::registerTag( $Name,\&_DoMacro,1 ) ;
  uHTML::registerVar( $Name,\&_getMacroValue,1 ) ;
}

sub DefinedVar
{
  my( $Node,$Par,$Var,$Name ) = @_ ;
  my $env  = $Node->{'ENV'} ;
  return( $Name ne '' && ( _testDefine( $env,$Name ) || _checkMacro( $env,$Name ) ) ? 1 : 0 ) ;
}

sub DefinedTag
{
  my $Node = shift ;
  my $env  = $Node->{'ENV'} ;
  my $Attr = $Node->attributes ;

  if( ref $Attr eq 'HASH' )
  {
    my $Name = $Attr->{'name'} ;
    _testDefine( $env,$_ ) || _checkMacro( $env,$_ ) || $_ eq 'name' && $Name ne '' or return foreach keys %{$Attr} ;
    return if $Name ne '' and not _testDefine( $env,$Name ) || _checkMacro( $env,$Name ) ;
  }
  $Node->map( '','' ) ;
}

sub NotDefinedVar
{
  my( $Node,$Par,$Var,$Name ) = @_ ;
  my $env  = $Node->{'ENV'} ;

  return( $Name ne '' && ( _testDefine( $env,$Name ) || _checkMacro( $env,$Name ) ) ? 0 : 1 ) ;
}

sub NotDefinedTag
{
  my $Node = shift ;
  my $env  = $Node->{'ENV'} ;
  my $Attr = $Node->attributes ;

  if( ref $Attr eq 'HASH' )
  {
    my $Name = exists $Attr->{'name'} ? $Attr->{'name'} : '' ;
    _testDefine( $env,$_ ) || _checkMacro( $env,$_ ) || $_ eq 'name' && $Name eq '' and return foreach keys %{$Attr} ;
    return if $Name ne '' and _testDefine( $env,$Name ) || _checkMacro( $env,$Name ) ;
  }
  $Node->map( '','' ) ;
}

sub _filterNode
{
  my( $Node,$R ) = @_ ;

  $Node->{Text}    =~ s/$R//gs ;
  $Node->{Trailer} =~ s/$R//gs ;

  for( my $Child = $Node->{FirstChild} ; $Child ; $Child = $Child->{Next} )
  {
    _filterNode( $Child,$R ) ;
  }
}

sub skipLF
{
  my $Node = shift ;

  my $R = $Node->testAttr( 'keepspaces' ) ? qr/\n/ :
          $Node->testAttr( 'allspaces' )  ? qr/(?:\s*\n\s*)+/ : qr/\n\s*/ ;
  _filterNode( $Node,$R ) ;
  if( $R = $Node->attr( 'tag' ) )
  {
    $Node->name( $R ) ;
    $Node->deleteAttr( 'keepspaces','allspaces','tag' ) ;
    $Node->insert() ;
    return ;
  }
  $Node->map( '','' ) ;
}

sub skipSpaces
{
  my $Node = shift ;

  my $R = qr/^\s*|\s*$/ ;
  _filterNode( $Node,$R ) ;
  if( $R = $Node->attr( 'tag' ) )
  {
    $Node->name( $R ) ;
    $Node->deleteAttr( 'tag' ) ;
    $Node->insert() ;
    return ;
  }
  $Node->map( '','' ) ;
}

sub ForEachVal
{
  return $_[0]->{'ENV'}->{'ForEachValue'} ;
}

sub ForEachCnt
{
  return $_[0]->{'ENV'}->{'ForEachCount'} ;
}

sub ForEachNum
{
  return $_[0]->{'ENV'}->{'ForEachCount'}+1 ;
}

sub Repeat( $ )
{
  my $Node = shift ;
  my $env  = $Node->{'ENV'} ;
  my $FEC  = $env->{'ForEachCount'} ;
  my $FEV  = $env->{'ForEachValue'} ;
  my $JOIN = $Node->testAttr( 'joint' ) ?  $Node->attr( 'joint' ) : $Node->attr( 'join' ) ;
  my $SKIP = not $Node->testAttr( 'skipempty' ) ;
  my( $SEP,$NC,$code,$S,$E,$I,$C,$F,$n,$i,@List ) ;

  if( $Node->testAttr( 'list' ) )
  {
    $SEP  = $Node->testAttr( 'separator' ) ? ($SEP=$Node->attr( 'separator' ),qr/$SEP/) : $RO ;
    @List = split $SEP,$Node->attr( 'list' ) ;
    @List = sort @List if $Node->testAttr( 'sort' ) or $Node->testAttr( 'uniq' ) ;
    @List = uniq @List if $Node->testAttr( 'uniq' ) ;
    $C    = $Node->testAttr( 'count' ) ? int( $Node->attr( 'count' ) ) : scalar @List ;
    $F    = $Node->testAttr( 'from' ) ? int( $Node->attr( 'from' ) ) - 1 : 0 ;
    for( $env->{'ForEachCount'}=0; $env->{'ForEachCount'}<$C; $env->{'ForEachCount'}++ )
    {
      $env->{'ForEachValue'} = $List[$env->{'ForEachCount'}] ;
      $NC = $Node->copy ;
      $NC->map( '','' ) ;
      next unless ($n = $NC->HTML()) or $SKIP ;
      $code .= $JOIN if $code ;
      $code .= $n ;
    }
  }
  elsif( $Node->testAttr( 'to' ) or $Node->testAttr( 'count' ) )
  {
    $S = int( $Node->testAttr( 'from' ) ? $Node->attr( 'from' ) : 1 ) ;
    $I = int( $Node->attr( 'step' ) ) ;
    $I = 1 unless $I ;
    $C = int( $Node->attr( 'count' ) ) ;
    $E = int( $Node->testAttr( 'to' )   ? $Node->attr( 'to' ) : $C*$I+$S ) ;
    if( $I != 0 and ($E-$S)*$I>=0 )
    {
      $n = int(($E-$S)/$I + 1) ;
      $C = $n if $C <= 0 or $n > 0  and $n < $C ;

      $env->{'ForEachCount'} = 0 ;
      for( $env->{'ForEachValue'}=$S; $C-- > 0; $env->{'ForEachValue'}+=$I )
      {
        $NC = $Node->copy ;
        $NC->map( '','' ) ;
        if( $SKIP or $NC->HTML() )
        {
          $code .= $JOIN if $code ;
          $code .= $NC->HTML() ;
        }
        $env->{'ForEachCount'}++ ;
      }
    }
  }
  $env->{'ForEachCount'} = $FEC ;
  $env->{'ForEachValue'} = $FEV ;
  $Node->HTML( $code ) ;
}

sub getListElement
{
  my( $Node,$Par,$Var,$List,$nr,$SEP ) = @_ ;

  unless( $Par )
  {
    $List = $Node->attr( 'list' ) ;
    $nr   = $Node->attr( 'nr' ) ;
    $SEP  = $Node->attr( 'separator' ) ;
  }
  return '' unless $List and $nr > 0 ;
  $SEP = $SEP ? qr/$SEP/ : $RO ;
  my @L = split $SEP,$List ;
  return '' if --$nr > $#L ;
  return $L[$nr] ;
}

sub useScript
{
  my( $Node,$Par,$Var,$Path,$error ) = @_ ;
  my( @E,$p,@P ) ;

  if( $Par )
  {
    @P = split( $SO,$Path ) ;
  }
  else
  {
    foreach( 'path','script','module','modules','dir' )
    {
      push @P,map uFilePath( $_,$Node->env() ),split $SO,$Node->attr( $_ ) if $Node->testAttr( $_ ) ;
    }
    push @P,split $SO,$Node->attr( 'use' ) if $Node->testAttr( 'use' ) ;
    map { require "uHTML/$_.pm" } split $SO,$Node->attr( 'uHTML' ) if $Node->testAttr( 'uHTML' ) ;
  }

  if( @P )
  {
    foreach $p( @P )
    {
      if( -d $p )
      {
        if( opendir DH,$p )
        {
          foreach( grep m/\.pm$/,readdir DH )
          {
            -r "$p/$_" ? { require "$p/$_" } : push @E,"$p/$_" ;
          }
        }
        else
        {
          push @E,$p ;
        }
      }
      elsif( -r $p  )
      {
        require $p ;
      }
      else
      {
        require $p
      }
    }
  }

  return '' ;
}

sub getENV
{
  my $N = $_[1] ? $_[3] : $_[0]->attr('name') ;
  return( $N ? $_[0]->{ENV}->{$N} : '' ) ;
}


sub ENVkeys
{
  my $S = $_[1] ? $_[4] : $_[0]->attr('separator') ;
  $S = ',' unless $S ;
  return join( $S, sort keys %{$_[0]->{ENV}} ) if $_[1] ? $_[3] : $_[0]->testAttr('sort') ;
  return join( $S, keys %{$_[0]->{ENV}} ) ;
}

uHTML::registerTag( 'if',\&DoIf ) ;
uHTML::registerTag( 'choice',\&Choice ) ;
uHTML::registerVar( 'choice',\&VarChoice ) ;
uHTML::registerTag( 'CondAttr',\&CondAttr ) ;
uHTML::registerTag( 'include',\&Include ) ;
uHTML::registerVar( 'include',\&VarInclude ) ;
uHTML::registerTag( 'insert',\&InsertText ) ;
uHTML::registerVar( 'uHTMLtoHTML',\&InsertText ) ;
uHTML::registerTag( 'define',\&Define ) ;
uHTML::registerTag( 'undef',\&ClearDef ) ;
uHTML::registerVar( 'defined',\&DefinedVar ) ;
uHTML::registerTag( 'defined',\&DefinedTag ) ;
uHTML::registerVar( 'notdefined',\&NotDefinedVar ) ;
uHTML::registerTag( 'notdefined',\&NotDefinedTag ) ;
uHTML::registerVar( 'Alternative',\&Alternative ) ;
uHTML::registerVar( 'AltText',\&AltText ) ;
uHTML::registerTag( 'macro',\&Macro ) ;
uHTML::registerTag( 'identity',\&Identity ) ;
uHTML::registerVar( 'identity',\&Identity ) ;
uHTML::registerTag( 'skipLF',\&skipLF ) ;
uHTML::registerTag( 'skipSpaces',\&skipSpaces ) ;
uHTML::register( 'ENV',\&getENV ) ;
uHTML::register( 'ENVkeys',\&ENVkeys ) ;
uHTML::register( 'replace',\&ReplaceText ) ;
uHTML::register( 'RepeatNum',\&ForEachNum ) ;
uHTML::register( 'RepeatCount',\&ForEachCnt ) ;
uHTML::register( 'RepeatValue',\&ForEachVal ) ;
uHTML::registerTag( 'repeat',\&Repeat ) ;
uHTML::registerTag( 'Repeat',\&Repeat ) ;
uHTML::register( 'uFilePath',\&getFilePath ) ;
uHTML::register( 'ListElement',\&getListElement ) ;
uHTML::register( 'Modules',\&useScript ) ;
uHTML::register( 'Module',\&useScript ) ;
uHTML::register( 'uModule',\&useScript ) ;



######################################
######################################

=pod

=encoding UTF-8

=head1 NAME

=over 2

=item B<uHTML::std> - standard B<HTML> tags

=for comment =item B<uHTMLnode> - central B<uHTML> data structure

=back

=head1 VERSION

Version 2.21

=head1 DESCRIPTION

Standard tags and functions are the most used uHTML tags and functions - think I<std.h> in B<C>.
They are used in nearly every B<uHTML> project. It brings programming capabilities directly
into the B<uHTML>-files and addresses rather the programmer than the designer, although most
designers value especially the tags B<include> and B<define> which use is quite obvious for them.
The tags B<if>/B<else>, B<choice>, B<repeat> and B<macro> are usually utilized with support
of the programmer. Due their compliance with the standard B<HTML>-syntax designers do not
hesitate to alter them without help of the programmer. While doing that the designer seldom
incorporate errors into the B<uHTML> file as the tags program code is not affected and
a faulty result can be noticed by the designer immediately.

=head1 REQUIREMENTS

This std library do not require any other libraries but the main B<uHTML> library.

=head1 uHTML tags provided by the std library

B< >

=head2 include

=head3 Overview

The include tag includes the content of a uHTML file into another uHTML-file.
It is intended to move constant parts of the website files like header lines,
menus, footers, etc. into one file and save thereby development and maintenance
time ans as well reduce probability of random mistakes.

=head3 Conventions

Path names beginning with '/' are considered as relative to DOCUMENT_ROOT.
Path names not beginning with '/' and not prefixed with '#' are considered as
relative to the path of the current file. Path names prefixed with '#' are considered
as file system absolute if a '/' follows the '#' and relative to DATA_ROOT
(or the script directory) if no '/' follows the '#'.

=head3 Attributes

=head4 file="FILEPATH"

The attribute file defines the path and name of the included file.

=head4 files="FILEPATH"

The attribute files defines the path and name of the included file whereby wildcards *
and ? are expanded according to glob rules and the included files get concatenated.

=head4 alt="FILEPATH"

In case no file defined by the file or files attributes is found, the file defined by
the alt attribute get included whereby wildcards * and ? are expanded according to
glob rules and the included files get concatenated.

=head4 raw

The attribute raw without value prevents the interpretation of uHTML-elements in the
included file. It should be used if files without uHTML-elements get included.

=head4 warn

The attribute warn without value allows error messages in case the included file
isn't found or is not readable.

=head4 cond="clause"

The cond attribute is optional. If present, then the include tag is executed only if
the clause in the attribute cond evaluates 'true'.

=head3 Example

  <include file="/include/navigation" >

=head2 define

=head3 Overview

The define tag defines new uHTML tags and variables assigning to each constant content
which isn't interpreted as uHTML. It helps to shorten source files abbreviating frequently
used code sequences. At the same time it reduces the risk of random errors while copying
of the same content across the site's source files. It is possible to define several tags
and variables within one define tag. It is advisable to use the include-tag to collect
definitions used in the whole site in one file.

=head3 Conventions

Previous definitions with the same name are saved and get recovered when a definition
done with define get revoked with undef unless the definition is done with the attribute replace.

=head3 Attributes

=head4 createonly

If a attribute createonly without any value is supplied,
only new definitions will be regarded. Existing definitions will be skipped.

=head4 replace

If a attribute replace without any value is supplied,
the last definition of a tag and variable will be replaced not recoverable by undef.

=head3 Example

=head4 Definition:

  E<lt>define uHTML='E<lt>span style="font-family:serif;color:#34a;"E<gt>
  E<lt>span style="font-weight:bold;color:#fe6f02; font-size:0.8em"E<gt>UE<lt>/span>HTMLE<lt>/spanE<gt>'
  bluestyle="color:blue;font-weight:bold;"E<gt>

=head4 Use:

  <uHTML> <span style="$bluestyle"> is exciting </span>

=head2 undef

=head3 Overview

The undef tag revokes definitions done with define. It recovers the previous definition if it exists.

=head3 Example

  <undef uHTML bluestyle>

=head2 macro

=head3 Overview

The macro tag allows to define complex new tags with own attributes within a uHTML file.
The uHTML-code within the tag defined with the macro tag is interpreted.
Definitions done with macro cannot be revoked like it can be done with definitions
done with define, but they can be replaced if the replace attribute
is supplied with the new definition.

Macros without own parameters can be used as variables in attributes.

=head3 Special Tag

=head4 <MacroBody>

The optional MacroBody tag within a macro definition marks the position of
the body when the macro is deployed as a closed tag. If the macro is deployed
as a not closed tag, MacroBody is ignored.

=head3 Attributes

=head4 name="MacroName"

The attribute name defines the name of the macro.

=head4 attributes="AttributeList"

The attribute attributes defines the valid attributes of the defined macro.
The attributes of the macro are given in a comma separated list.
It is possible to define default values for the macro attributes.
Those default values are separated by a '=' from the attribute name.
Leading and trailing spaces are ignored unless the value is included
in single or double quotation marks. The value must not contain any comma.

=head4 replace

The attribute replace forces the replacement of a former macro definition
with the same name. Without the attribute replace the definition get ignored
if a macro with the same name exists.

=head3 Example

=head4 Definition:

  <macro name="Label" attributes="text">
    <div class="toplabel"><text></div>
  </macro>

=head4 Use:

  <Label text="Home">

=head4 Definition:

  <macro name="Box" attributes="color,background=white">
    <div class="boxclass" style="color:$color;background-color:$background">
      <MacroBody>
    </div>
  </macro>

=head4 Use:

  <Box color="blue" background="#e3fff6">Boxtext</Box>

=head2 defined

=head3 Overview

The defined tag content is included in the uHTML output if all attributes
without a value equal to a name defined with define or macro or if the value
of the attribute name contains a name defined either with define or with macro.

=head3 Attributes

=head4 name="name"

The name of the define or macro which should be tested for existence.

=head3 Example

  <defined name="Count">
    <Count>
  </defined>

=head2 notdefined

=head3 Overview

The notdefined tag content is included in the uHTML output if none
of the attributes without a value equals to a name defined with define
or macro or if the value of the attribute name do not contains a name
defined either with define or with macro.

=head3 Attributes

=head4 name="name"

The name of the define or macro which should be tested for existence.

=head3 Example

  <notdefined name="bluestyle">
    <define bluestyle="color:blue;font-weight:bold;">
  </notdefined>

=head2 if

=head3 Overview

The tag if allows conditional content.
It usually contains one ore more else tags which enclose alternative content.

=head3 Attributes

=head4 cond="clause"

The clause in the attribute cond decides if the content of the if tag
is processed and passed to the http client. It is interpreted as a perl expression.
It is true if the result is not 0 or it contains a string with a non-zero length.
In the latter case the string need to be enclosed in quotation marks within
the quotation marks of the attribute value.

If the attribute content evaluates 'true' the content of the tag
is processed and passed on while the content of subordinated else-tags is ignored.
In opposite case the tag content is discarded while the else tags get evaluated.

=head3 Example

  <if cond="$File ne 'index.uhtml'">
    <a href="/index.uhtml">Home</a>
  </if>

=head2 else

=head3 Overview

The tag else used within a if tag defines alternative content.
If it contains the attribute cond, it's content get only processed and passed on
if the clause in the attribute cond evaluates 'true'. In this case all other
  else tags within the parental if tag get discarded along with the content of the if tag.

=head3 Attributes

=head4 cond="clause"

The clause in the attribute cond decides if the content of the else tag is processed
and passed to the http client. It is interpreted as a perl expression.
It is true if the result is not 0 or it contains a string with a non-zero length.
In the latter case the string need to be enclosed in quotation marks within the
quotation marks of the attribute value.

If the attribute content evaluates 'true' the content of the tag is processed
and passed on while the content of all other else tags within the parental
if tags get discarded along with the content of the if tag.

=head3 Example

  <if cond="$File ne 'index.uhtml'">
    <a href="/index.uhtml">Home</a>
    <else><img src="spacer.png" alt="placeholder"></else>
  </if>

=head2 choice

=head3 Overview

The deployment of if tags with an included else tag is always text-intensive.
Sometimes just two tags or just two attribute values in some attributes of a
tag make the difference. In such cases the tag choice is often the better alternative.
The tag choice can be used as open or closed tag. The alternative values of the attributes
need to be separated by "|". In case the clause in the attribute cond evaluates true,
the value left of "|" is used, otherwise the value right of "|". If the value has a zero length, the attribute is omitted.

=head3 Attributes

=head4 cond="clause"

The clause in the attribute cond decides if the content on the left or the content
on the right side of "|" in the attribute values is used. If no "|" is found in an
attributes value, the value is used independent of the condition.

=head4 tag="ELEMENTNAME"

The attribute tag defines the name of the tag by which choice will be replaced.
It is obligatory and in case it is missing or equals to a zero length string,
the whole tag is omitted. It can contain two values separated by "|" which will
be used according to the result of cond.

=head4 attr="AttributeList"

A comma separated list of attributes without values which have to be added to the tag.
Two lists separated by "|" can be defined. The lists will be used according to the result of cond.

=head3 Example

  <choice cond="'$ENV(HTTP_USER_AGENT)' =~ m/Explorer/" tag="div" class="explorer|normal">
    ....Text....
  </choice>

=head2 CondAttr

=head3 Overview

CondAttr drops all empty attributes. It is meant to avoid empty attributes which may confuse browsers.

=head3 Attributes

=head4 tag="ELEMENTNAME"

The attribute tag defines the name of the tag by which CondAttr will be replaced.
It is obligatory and in case it is missing or equals to a zero length string, the whole tag is omitted.

=head3 Example

  <CondAttr tag="div" class="$SpecialClass">
    ....Text....
  </CondAttr>

=head2 replace

=head3 Overview

The tag replace applies perl regular expressions to the text provided by the attribute
text and inserts it into the HTML code. For more information on perl regular expressions,
please consult the corresponding man page perlre.

=head3 Attributes

=head4 text="TEXT"

The text to be altered.

=head4 pattern="RegExPattern"

Patterns of the regular expression. Notice that backslashes "\" must be escaped (doubled) "\\".

=head4 replace="ReplaceText"

Text that will replace pattern. Notice that "$" signs must be escaped "\$".

=head4 options="OPTIONS"

Replace options. For more information about possible options
please consult the perl regular expressions man page perlre.

=head3 Example

  <replace text="$include(#data/products)" pattern="," replace="<br>">

=head2 skipLF

=head3 Overview

The tag skipLF removes line feeds and any spaces and tabs following it,
speak any spaces or tabs at the beginning of a line. It helps to keep the
source code readable while allowing e.g. place images adjacent.
It is especially useful with the tags macro and repeat.

=head3 Attributes

=head4 keepspaces

Remove line feeds only and keep all spaces.

=head4 allspaces

Remove spaces at the end of the lines as well.

=head4 tag="ELEMENTNAME"

If present, the attribute tag defines the name of a tag by which skipLF
will be replaced. If it is missing or equals to a zero length string,
the attribute is treated as not existent.

=head3 Example

  <skipLF>
    <img src="/img/left.gif">
    <img src="/img/right.gif">
  </skipLF>

=head2 skipSpaces

=head3 Overview

Within the tag skipSpaces spaces, tabs and line feeds ahead and following
any tag are removed. It helps to keep the source code readable while allowing
e.g. place images adjacent. It is especially useful with the tags macro and repeat.

=head3 Attributes

=head4 tag="ELEMENTNAME"

If present, the attribute tag defines the name of a tag by which skipSpaces
will be replaced. If it is missing or equals to a zero length string,
the attribute is treated as not existent.

=head3 Example

  <skipSpaces>
    <img src="/img/left.gif">
    <img src="/img/right.gif">
  </skipSpaces>

=head2 repeat

=head2 Repeat

=head3 Overview

The tag repeat repeats itself according to the values of it's attributes.
The repeat tags can be nested. The variants repeat and Repeat are identical.

=head3 Attributes

=head4 list="ValueList"

A list of values separated by separator. The tag repeat is repeated once for
each element of the list. If list is defined, other attributes are ignored.

=head4 separator="REGEX"

A regular expression used to split the list. If omitted the values in list
must be separated by commas, colons or semicolons surrounded by optional (ignored) spaces (\s*[,;:]\s*).

=head4 sort

Valid only if the list attribute is given.
If present, the list will be sorted alphabetically before the execution of repeat.

=head4 uniq

Valid only if the list attribute is given.
If present, identical adjacent values of list are ignored. if the attribute sort is given,
uniq is applied on the sorted list.

=head4 skipempty

Valid only if the list attribute is given. If present, empty list elements are ignored.

=head4 from="integer"

The attribute from defines the initial value to count the iterations. If not defined it defaults to 1.

If the attribute list is given, it defines the initial list element to be used. The first list element is referred by 1.

=head4 step="integer"

The attribute step defines the increment value for a iteration. It can have a negative value.
If not defined it defaults to 1. It is ignored if the attribute list is given.

=head4 to="integer"

The attribute to defines the last value for a iteration.
If not defined it defaults to 0. It is ignored if the attribute list is given.

=head4 count="integer"

The attribute to defines the count of iteration.
If not defined it defaults to 0. It is ignored if to is defined and different from 0.

If the attribute list is given, it defines the count of elements to be used.

=head4 joint="text"

Text inserted between the repetitions of repeat. It can contain HTML tags. uHTML tags and variables will be ignored.

If uHTML tags and variables should get interpreted, the function $uHTMLtoHTML can be used.

=head3 Example

  <center><repeat count="11" >#</repeat></center>

=head2 RepeatCount

=head3 Overview

The tag RepeatCount is valid within the repeat tag. It returns the count of completed iterations of the tag repeat.

=head3 Example

  <repeat count="20"><RepeatCount> completed<br></repeat>

=head2 RepeatNum

=head3 Overview

The tag RepeatNum is valid within the repeat tag. It returns the number of the current iteration of the tag repeat.

=head3 Example

  <repeat count="20">Am in iteration <RepeatNum><br></repeat>

=head2 RepeatValue

=head3 Overview

The tag RepeatValue is valid within the repeat tag.
It returns the current value associated the current iteration of the tag repeat.
In case the overlying repeat tag has the attribute list, it returns the
corresponding list value. Otherwise it returns the value calculated according
to the attributes from and step of the overlying repeat tag.

=head3 Example

  <repeat count="10">Line <RepeatValue><br></repeat>

=head2 ListElement

=head3 Overview

The tag ListElement extracts an single element from a text list.
It is ineffective and should be only used to occasionally extract
a single list element and must be never used within a loop.

=head3 Attributes

=head4 list="LIST"

The list from which the element hast to be extracted. If missing or empty the tag is omitted.

=head4 nr="NUMBER"

Number of the element to be extracted.
The first element in the list has the number 1. If missing or out of range the tag is omitted.

=head4 SEP="REGEX"

Element separator used in the list.
If omitted it defaults to commas, colons or semicolons surrounded by optional (ignored) spaces (\s*[,;:]\s*).

=head3 Example

  <ListElement list="A, B, C" nr="2">

=head2 uFilePath

=head3 Overview

The tag uFilePath determines the absolute path of a file according
to the uHTML path name conventions. Path names beginning with '/'
are considered as relative to DOCUMENT_ROOT. Path names not
beginning with '/' and not prefixed with '#' are considered as
relative to the path of the current file. Path names prefixed
with '#' are considered as file system absolute if a '/' follows
the '#' and relative to DATA_ROOT (or the script directory) if no '/' follows the '#'.

=head3 Attributes

=head4 path="PATH"

Path to convert.

=head3 Example

  Document Root: <uFilePath path="/">

=head2 ENV

=head3 Overview

The tag ENV inserts the value of the environment variable name into the HTML-code.

=head3 Attributes

=head4 name="EnvVarName"

Name of the environment variable.

=head3 Example

  <ENV name="SERVER_NAME">

=head2 ENVkeys

=head3 Overview

The tag ENVkeys inserts a list of all environment variables names into the HTML-code.

=head3 Attributes

=head4 separator="SEPARATOR"

Separator between the names to be used in the list. Defaults to "," if omitted.

=head4 sort

If the attribute sort is present, the list is sorted.

=head3 Example

  <ENVkeys>

=head2 insert

=head3 Overview

The tag insert inserts the value of the attribute text into the HTML-code.
The attribute raw prevents the interpretation of uHTML elements in text.
This tag is used mainly for site debugging purposes.

=head3 Attributes

=head4 text="Text"

Text inserted into HTML.

= head4 raw

The attribute raw prevents the interpretation of uHTML elements in text.

=head3 Example

  <insert text="$testfunc(A,1)">

=head2 identity

=head3 Overview

The tag identity does literal nothing. This tag is used mainly for site debugging purposes.

=head3 Example

  <identity>Text</identity>

=head2 uModule

=head3 Overview

The tag uModule makes perl modules (usually uHTML modules) accessible within the website.

=head3 Attributes

=head4 path="FileName"

=head4 script="FileName"

=head4 module="FileName"

=head4 modules="FileName"

=head4 dir="FileName"

The filename of the required module. The attribute can contain several module names
separated by commas. The file names are interpreted according to the uHTML file name
conventions. Path names beginning with '/' are considered as relative to DOCUMENT_ROOT.
Path names not beginning with '/' and not prefixed with '#' are considered as relative
to the path of the current file. Path names prefixed with '#' are considered as file
system absolute if a '/' follows the '#' and relative to DATA_ROOT (or the script
directory) if no '/' follows the '#'.

=head4 error

The attribute error forces error messages in the servers log files.

=head3 Example

  <uModule script="inc/edit/uHTML/edit.pm">

B< >

B< >

=head1 Attribute variables and functions provided by the std library

B< >

=head2 $defined(name)

=head3 Overview

The $defined function is used mainly within the cond attribute of different tags.

=head3 Parameters

=head4 name

The name of a definition either by define or by macro which should be tested for existence.

=head3 Example

  <if cond="$defined(Products)">
    <Products>
  </if>

=head2 $notdefined(name)

=head3 Overview

The $notdefined function is used mainly within the cond attribute of different tags.

=head3 Parameters

=head4 name

The name of a definition either by define or by macro which should be tested for existence.

=head3 Example

  <include cond="$notdefined(Products)" file="#inc/products">

=head2 $choice(cond,true,false)

=head3 Overview

Sometimes even the tag choice is to complex to choose between two alternative values for one attribute or two different attributes of the same tag need different values depending on different conditions for each attribute. For such cases the function $choice is defined.

=head3 Parameters

=head4 cond

Depending on the result of the clause in the parameter cond, either the value of the parameter true or the value of the parameter false is returned by the function choice.

=head4 true

Value returned if cond evaluates true.

=head4 false

Value returned if cond evaluates false.

=head3 Example

  <div class="$choice($SiteName,std,special)">

=head2 $Alternative(par1,par1,par3,…)

=head3 Overview

Sometimes the first true (in sense of perl) out of many values is needed.
For such cases the function $Alternative is defined. $Alternative returns
the first parameter which isn't an empty string or zero. To use it as a tag
wrap it into the tag insert.

=head3 Parameters

=head4 par1,par1,par3,…

The first par* parameter which isn't an empty string or zero will be returned by the function Alternative.

=head3 Example

  <insert text="$Alternative($FormData,$Default)">

=head2 $AltText(par1,par1,par3,…)

=head3 Overview

Sometimes the first value containing some text out of many values is needed.
For such cases the function $AltText is defined. $AltText returns the first
parameter which isn't an empty string. To use it as a tag wrap it into the tag insert.

=head3 Parameters

=head4 par1,par1,par3,…

The first par* parameter which isn't an empty string will be returned by the function AltText.

=head3 Example

  <insert text="$AltText($FormData,$Default)">

=head2 $include(file,alt)

=head3 Overview

The function $include inserts the content of a file into a attribute.
The file names are interpreted according to the uHTML file name conventions.
Path names beginning with '/' are considered as relative to DOCUMENT_ROOT.
Path names not beginning with '/' and not prefixed with '#' are considered
as relative to the path of the current file. Path names prefixed with '#' are
considered as file system absolute if a '/' follows the '#' and relative to
DATA_ROOT (or the script directory) if no '/' follows the '#'.

=head3 Parameters

=head4 file

The parameter file defines the path and name of the included file. Wildcards * and ? are expanded according to glob rules and the included files get concatenated.

=head4 alt

In case no file defined by the file parameter is found, the file defined by the alt parameter get included. This parameter can be omitted.

=head3 Example

  <select name="products">
    <repeat list="$include(#data/products)">
      <option><RepeatValue></option>
    </repeat>
  </select>

=head2 $replace(text,pattern,replace,options)

=head3 Overview

The function $replace applies perl regular expressions to the text provided
by the parameter text before returning it. For more information on perl
regular expressions, please consult the corresponding man page perlre.

=head3 Parameters

=head4 text

The text to be altered.

=head4 pattern

Patterns of the regular expression. Notice that backslashes "\" must be escaped (doubled) "\\".

=head4 replace

Text that will replace pattern. Notice that "$" signs must be escaped "\$".

=head4 options

Replace options. For more information about possible options please consult the perl regular expressions man page perlre.

=head3 Example

  <insert text="$replace('$include(#data/products)',',','<br>')">

=head2 $RepeatCount()

=head3 Overview

The variable $RepeatCount is valid within the repeat tag.
It returns the count of completed iterations of the tag repeat.

=head3 Example

  <select name="weekday">
    <repeat list="Monday,Tuesday,Wednesday,Thursday.Friday,Saturday,Sunday">
      <option value="$RepeatCount"><RepeatValue></option>
    </repeat>
  </select>

=head2 $RepeatNum()

=head3 Overview

The variable $RepeatNum is valid within the repeat tag.
It returns the number of the current iteration of the tag repeat.

=head3 Example

  <select name="weekday">
    <repeat list="Monday,Tuesday,Wednesday,Thursday.Friday,Saturday,Sunday">
      <option value="$RepeatCount"><RepeatNum>: <RepeatValue></option>
    </repeat>
  </select>

=head2 $RepeatValue()

=head3 Overview

The variable $RepeatValue is valid within the repeat tag.
It returns the current value associated the current iteration of the tag repeat,
e.g. the corresponding value from the attribute list.

=head3 Example

  <select name="weekday">
    <repeat list="Monday,Tuesday,Wednesday,Thursday.Friday,Saturday,Sunday">
      <option value="$RepeatNum"><RepeatValue></option>
    </repeat>
  </select>

=head2 $ListElement(List,nr,SEP)

=head3 Overview

The variable $ListElement extracts an single element from a text list.
It is ineffective and should be only used to occasionally extract a single
list element and must be never used within a loop.

=head3 Parameters

=head4 list

The list from which the element hast to be extracted. If empty the result is an empty string.

=head4 nr

Number of the element to be extracted. The first element in the list has the number 1.
If missing or out of range the result is an empty string.

=head4 SEP

Element separator used in the list. If omitted it defaults to \s*[,;:]\s*.

=head3 Example

  <insert text="$ListElement( 'A, B, C',2 )">

=head2 $uFilePath(path)

=head3 Overview

The function $uFilePath determines the absolute path of a file according
to the uHTML path name conventions. Path names beginning with '/' are
considered as relative to DOCUMENT_ROOT. Path names not beginning with '/'
and not prefixed with '#' are considered as relative to the path of the
current file. Path names prefixed with '#' are considered as file system
absolute if a '/' follows the '#' and relative to DATA_ROOT (or the script
directory) if no '/' follows the '#'.

=head3 Parameters

=head4 path

Path to convert.

=head3 Example

  <if cond="-f '$uFilePath(/index.html)'"> <code>/index.html</code> exists. </if>

=head2 $ENV(name)

=head3 Overview

The function $ENV inserts the value of the environment variable name into a attribute.

=head3 Parameters

=head4 name

Name of the environment variable.

=head3 Example

  <if cond="'$ENV(HTTP_VIA)'"> Request passed a proxy server. </if>

=head2 $ENVkeys(sort,separator)

=head3 Overview

The function $ENV inserts the value of the environment variable name into a attribute.

=head3 Parameters

=head4 sort

If true the list get sorted.

=head4 separator

Separator between the names to be used in the list. Defaults to "," if omitted.

=head3 Example

  <repeat list="$ENVkeys(sort,';')">
    <div><RepeatValue>=<ENV name="$RepeatValue"></div>
  </repeat>

=head2 $identity(value)

=head3 Overview

The function $identity does literal nothing.
It just returns the unchanged parameter value. This tag is used mainly for site debugging purposes.

=head3 Parameters

=head4 value

The parameter value defines the return value of the function $identity.

=head3 Example

  <insert text="$identity(Text)">

=head2 $uHTMLtoHTML(uHTML)
,
=head3 Overview

The function $uHTMLtoHTML forces a parameter to be interpreted
as B<uHTML> input and be translated into B<HTML>.

=head3 Parameters

=head4 uHTML

The parameter uHTML get translated into HTML.

=head3 Example

  <skipLF>
    <repeat count="20" joint="$uHTMLtoHTML(<RecordSeparator>)">
      <Record num="$RepeatCount">
    </repeat>
  </skipLF>

B< >

B< >

=head1 perl functions provided by the uHTML::std library

B< >

=head2 uFilePath($path,$env)

=head3 Overview

The function uFilePath determines the absolute path of a file according to the uHTML path name conventions and the environment $env.
Path names beginning with '/' are considered as relative to DOCUMENT_ROOT. Path names not beginning with '/' and not prefixed with '#'
are considered as relative to the path of the current file. Path names prefixed with '#' are considered as file system absolute if a '/'
follows the '#' and relative to DATA_ROOT (or the script directory) if no '/' follows the '#'.

=head3 Parameters

=head4 $path

Path to convert.

=head4 $env

Environment in which's context the path should be converted

=head3 Example

  if(-f uFilePath('/index.html',$env)) {...



=head1 SEE ALSO

perl(1), uHTML, http://www.uhtml.de/en/doc/std.uhtml



=head1 AUTHOR

Roland Mosler (Roland.Mosler@Place.Ug)

=head1 COPYRIGHT

Copyright 2009 Roland Mosler.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


