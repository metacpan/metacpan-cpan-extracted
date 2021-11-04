
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

package uHTML::request ;

use version ; our $VERSION = "1.83" ;

require uHTML ;
use LWP::MediaTypes ;
use URI::Escape ;
use IO::Handle ;
use Time::Local( 'timegm','timelocal_nocheck' ) ;
use POSIX qw( strftime setlocale LC_TIME ) ;

my( @initRequest, @finishRequest ) ;

my @Empty = () ;

sub new
{
  my $class   = shift ;
  my $env     = shift ;
  my $req ;

  unless( ref $env eq 'HASH' )
  {
    my %E = %ENV ;
    $env = \%E ;
  }

  $env->{'PATH_INFO'}     =~ s%/*$%% ;
  $req->{'ENV'}           = $env ;
  $req->{'charset'}       = 'utf-8' ;
  $req->{'home'}          = $env->{'DATA_ROOT'} ? $env->{'DATA_ROOT'} : $env->{'SCRIPT_ROOT'} ;
  $req->{'Root'}          = $env->{'DOCUMENT_ROOT'} ;
  $req->{'Root'}         .= $env->{'REDIRECT_ROOT'} if $env->{'REDIRECT_ROOT'}  ;

  my $ru                  = $env->{'REQUEST_URI'} =~ s/\?.*//r ;
  $req->{'Request'}       = [ split m%/+%,$ru,-1 ] ;
  $req->{'Path'}          = [ split m%/+%,$env->{'PATH_INFO'},-1 ] ;
  $req->{'file'}          = $req->{'Root'} . $env->{'PATH_INFO'} ;

  if( -d $req->{'file'} )
  {
    $req->{'file'}       .= '/index.uhtml' ;
    $req->{'File'}        = 'index.uhtml' ;
    $req->{'RequestFile'} = 'index.uhtml';
  }
  else
  {
    $req->{'File'}        = pop @{$req->{'Path'}} ;
    $req->{'RequestFile'} = pop @{$req->{'Request'}} ;
  }

  $req->{'BaseName'}      = $req->{'File'} =~ s/\.[^\.]*$//ir ;
  $req->{'RequestName'}   = $req->{'RequestFile'} =~ s/\.[^\.]*$//ir ;
  $req->{'path'}          = join '/',@{$req->{'Path'}} ;
  $req->{'Path'}->[0]     = $env->{'HOST_NAME'} ? $env->{'HOST_NAME'} : $env->{'SERVER_NAME'} ;
  $req->{'request'}       = join '/'.@{$req->{'Request'}} ;
  $req->{'Request'}->[0]  = $env->{'HTTP_HOST'} ;

  return( $env->{'uRequest'} = bless( $req,$class ) ) ;
}

sub Init
{
  my $self = shift ;

  if( @_ )
  {
    my $func ;

    foreach $func( @_ )
    {
      next if ref $func ne 'CODE' ;
      next if grep $func == $_,@initRequest ;
      push @initRequest,$func ;
    }
  }
  elsif( ref $self eq 'uHTML::request' and not $self->{'InitRequest'} )
  {
    uHTML::loadModules( $self->{'ENV'} ) ;
    my @icopy = @initRequest ;  # side effect protection
    $_->($self) foreach @icopy ;
    $self->{'InitRequest'} = 1 ;
  }
  return $self ;
}

sub Finish
{
  my $self = shift ;

  if( @_ )
  {
    my $func ;

    foreach $func( @_ )
    {
      next if ref $func ne 'CODE' ;
      next if grep $func == $_,@finishRequest ;
      push @finishRequest,$func ;
    }
  }
  elsif( ref $self eq 'uHTML::request' and not $self->{'FinishRequest'}  )
  {
    my @icopy = @finishRequest ;  # side effect protection
    $_->($self) foreach @icopy ;
    $self->{'FinishRequest'} = 1 ;
  }
  return $self ;
}

sub ENV
{
  my $self = shift ;

  $self->{'ENV'} = shift if @_ ;
  return $self->{'ENV'} ;
}

sub QueryData
{
  my $self = shift ;
  my $Name = shift ;
  my( $n,$v ) ;

  unless( $self->{'Query'} )
  {
    my %Q ;

    $self->{'Query'} = \%Q ;
    foreach( split /\&/,$self->{'ENV'}->{'QUERY_STRING'} )
    {
      ( $n,$v ) = m/([^\=]+)(?:\=(.*))?/ ;
      if( $n )
      {
        if( $v ne '' )
        {
          $v =~ s/\+/ /g ;
          push @{$self->{'Query'}->{uri_unescape($n)}},uri_unescape($v) ;
        }
        elsif( $n =~ m/^(\d+)(\w+)/ )
        {
          push @{$self->{'Query'}->{uri_unescape($2)}},$1 ;
        }
        else
        {
          $self->{'Query'}->{uri_unescape($n)} = \@Empty ;
        }
      }
    }
  }
  return $self->{'Query'} unless $Name ;
  return (wantarray ? @Empty : '') unless $self->{'Query'}->{$Name} ;
  return (wantarray ? @{$self->{'Query'}->{$Name}} : $self->{'Query'}->{$Name}->[0]) ;
}

# RFC2046
my $BounduaryTest = qr%[\dA-Za-z'()+_,-./:=?]{1,70}% ;
my $CRLF          = qr/\r\n/ ;

sub _getMultiPartData
{
  my( $Struct,$Data,$bounduary,$length ) = @_ ;
  my( $line,$bound,$end,$status,$Record,$handling ) ;

  my( $cnt ) ;

  return 0 unless ref $Struct eq 'HASH' ;
  $bound  = qr/^--$bounduary/ ;
  $end    = "--$bounduary--" ;


  for( undef $status;;$cnt++ )
  {
    last unless $Data =~ m/(.*?)\r\n/sgc ;

    unless( $line = $1 or $status eq 'data' )
    {
      $status = 'data' if $status eq 'head' and ref $Record eq 'HASH' ;
      next ;
    }

    if( $line =~ $bound )
    {
      if( ref $Record eq 'HASH' and $Record->{'label'} )
      {
        if( $Record->{'name'} )
        {
          $Record->{'length'} = length $Record->{'data'} ;
          push( @{$Struct->{$Record->{'label'}}},$Record ) ;
        }
        elsif( $Record->{'type'} eq 'multipart/form-data' and $Record->{'boundary'} )
        {
          _getMultiPartData( $Struct,$Record->{'data'},$Record->{'boundary'},length $Record->{'data'} ) ;
        }
        else
        {
          push( @{$Struct->{$Record->{'label'}}},$Record->{'data'} ) if $Record->{'data'} ;
        }
      }
      $status = 'complete', last if $line eq $end ;

      my %H ; $Record = \%H ;
      $status = 'head' ;
      next ;
    }

    next unless ref $Record eq 'HASH' ;

    if( $status eq 'data' )
    {
      $Record->{'data'} .= "\r\n" if $Record->{'data'} ;
      $Record->{'data'} .= $line ;
      next ;
    }
    elsif( $status eq 'head' )
    {
      $handling = ($line =~ m/^Content-([\w-]+): +/gs)[0] ;
      if( $handling eq 'Disposition' )
      {
        ( $Record->{'label'},$Record->{'name'} ) = ($line =~ m/form-data; +name="((?:[^"\\]|\\.?)+)"(?:; +filename="((?:[^"\\]|\\.?)+)")?/cgs ) ;
      }
      elsif( $handling eq 'Type' )
      {
        ( $Record->{'type'},$Record->{'boundary'} ) = ($line =~ m%([\w-/]+) *; boundary="?($BounduaryTest)"?%cgs) ;
      }
      elsif( $handling eq 'Transfer-Encoding' )
      {
        $Record->{'encoding'} = ($line =~ m/([^;]+);/cgs)[0] ;
      }
    }
  }
  return $status ;
}

sub PostData
{
  my $self = shift ;
  my $Name = shift ;

  unless( $self->{'Post'} )
  {
    return \@Empty unless $self->{'ENV'}->{'REQUEST_METHOD'} eq 'POST' and $self->{'ENV'}->{'CONTENT_LENGTH'} > 0 ;

    my( $n,$v,$PostData,$sep ) ;
    my( %P,$IO ) ;

    $self->{'Post'} = \%P ;
    $self->{'PostL'} = $self->{'ENV'}->{'CONTENT_LENGTH'} ;
    $self->{'PostR'} = 0 ;
    unless( $IO = $self->{'ENV'}->{'psgi.input'} )
    {
      $IO = IO::Handle->new() ;
      undef $IO unless $IO->fdopen( fileno( STDIN ),"r" ) ;
    }

    if( $IO )
    {
      while( $self->{'PostL'}>$self->{'PostR'} )
      {
        $self->{'PostR'} += $IO->read( $PostData,$self->{'PostL'}-$self->{'PostR'},$self->{'PostR'} ) ;
      }
    }

    return \@Empty unless $self->{'PostR'} > 0 ;


    if( $sep = ($self->{'ENV'}->{'CONTENT_TYPE'} =~ m%^multipart/form-data *; *boundary="?($BounduaryTest)"?%)[0] )
    {
      _getMultiPartData( $self->{'Post'},$PostData,$sep,$self->{'PostL'} ) ;
    }
    else
    {
      foreach( split /\&/,$PostData )
      {
        ( $n,$v ) = m/([^\=]+)(?:\=(.*))?/ ;
        if( $n )
        {
          if( $v ne '' )
          {
            $v =~ s/\+/ /g ;
            push @{$self->{'Post'}->{uri_unescape($n)}},uri_unescape($v) ;
          }
          elsif( $n =~ m/^(\d+)(\w+)/ )
          {
            push @{$self->{'Post'}->{uri_unescape($2)}},$1 ;
          }
          else
          {
            $self->{'Post'}->{uri_unescape($n)} = \@Empty ;
          }
        }
      }
    }
  }
  return $self->{'Post'} unless $Name ;
  return (wantarray ? @Empty : '') unless $self->{'Post'}->{$Name} ;
  return (wantarray ? @{$self->{'Post'}->{$Name}} : $self->{'Post'}->{$Name}->[0]) ;
}

sub Data
{
  my $self = shift ;
  my $Name = shift ;

  unless( $self->{'Data'} )
  {
    my %D ;

    $self->{'Data'} = \%D ;
    $self->PostData('') ;
    $self->QueryData('') ;
    foreach( keys %{$self->{'Post'}} )
    {
      push @{$self->{'Data'}->{$_}},@{$self->{'Post'}->{$_}} if $self->{'Post'}->{$_} ;
    }
    foreach( keys %{$self->{'Query'}} )
    {
      push @{$self->{'Data'}->{$_}},@{$self->{'Query'}->{$_}} if $self->{'Query'}->{$_} ;
    }

  }

  return $self->{'Data'} unless $Name ;
  return (wantarray ? @Empty : '') unless exists $self->{'Data'}->{$Name} ;
  return (wantarray ? @{$self->{'Data'}->{$Name}} : (ref $self->{'Data'}->{$Name} eq 'HASH' ? $self->{'Data'}->{$Name} : $self->{'Data'}->{$Name}->[0])) ;
}

sub Cookie
{
  my $self   = shift ;
  my $Name   = uri_escape_utf8( shift ) ;   # cookie name
  my $Value  = uri_escape_utf8( shift ) ;   # cookie value

  return $self->{'ENV'}->{'HTTP_COOKIE'} unless $Name ;
  unless( defined $self->{'RecvCookie'} or not $self->{'ENV'}->{'HTTP_COOKIE'} )
  {
    my %C = map uri_unescape($_),map split( /=/ ),split /;\s+/,$self->{'ENV'}->{'HTTP_COOKIE'} ;
    $self->{'RecvCookie'} = \%C ;
  }
  return( defined $self->{'RecvCookie'} ? $self->{'RecvCookie'}->{$Name} : undef ) unless defined $Value ;

  my $expire   = shift ;              # expiration in seconds, hours, days, months, or years (suffix none or s, h, d, m, y), 0 deletes the cookie
  my $path     = shift ;              # cookie path ('/' if not defined)
  my $host     = shift ;              # host ($ENV{'SERVER_NAME'} if not defined)
  my $JS       = shift ;              # if true, then the cookie is available via JavaScript
  my $SameSite = shift or 'strict' ;  # Google's Same Site Policy":  Strict, Lax or None

  $path = '/' unless defined $path ;
  $host = $self->{'ENV'}->{'SERVER_NAME'} unless defined $host ;
  $self->{'SendCookie'}->{$Name} = "$Name=$Value;" ;
  if( $expire )
  {
    my @Date = gmtime( 0 ) ;
    $expire  =~ m/(\d*)([shdmy]?)/ ;
    if( $1+0 )
    {
      my $F   = $2 ? $2 : 's' ;
      my @Lgt = ( 60,60,24,30,12 ) ;
      my %Fld = ( 's' => 0, 'h' => 2, 'd' => 3, 'm' => 4, 'y' => 5 ) ;
      @Date = localtime( time ) ;
      $Date[$Fld{$F}] += $1 ;
      $Date[$_] >= $Lgt[$_] and $Date[$_+1] += int($Date[$_]/$Lgt[$_]), $Date[$_] %= $Lgt[$_] foreach 0,1,2,4 ;
      @Date = gmtime( timelocal_nocheck( @Date[0 .. 5] ) ) ;
    }
    $self->{'SendCookie'}->{$Name} .= strftime( " Expires=%a, %d %b %Y %T UTC;",@Date )  ;
  }
  $self->{'SendCookie'}->{$Name} .= " Path=$path;" if $path ;
  $self->{'SendCookie'}->{$Name} .= " Domain=$host;" ;
  $self->{'SendCookie'}->{$Name} .= " sameSite=$SameSite;" ;
  $self->{'SendCookie'}->{$Name} .= " HttpOnly" unless $JS ;
  return $self->{'RecvCookie'}->{$Name} ;
}

sub ContentType
{
  my $self = shift ;


  $self->{'contentType'} = shift if @_ ;
  return $self->{'contentType'} if $self->{'contentType'} ;

  if( not $self->File() or $self->File() =~ /\.u?html?$/i ) { return( $self->{'contentType'} = 'text/html' ) }
  elsif( $self->File() =~ /\.u?css$/i )                     { return( $self->{'contentType'} = 'text/css' ) }
  elsif( $self->File() =~ /\.u?js$/i )                      { return( $self->{'contentType'} = 'text/js' ) }
  elsif( $self->File() =~ /\.u?xml$/i )                     { return( $self->{'contentType'} = 'text/xml' ) }
  elsif( $self->File() =~ /\.u?rss$/i )                     { return( $self->{'contentType'} = 'application/rss+xml' ) }

  return( $self->{'contentType'} = guess_media_type( $self->File() ) || 'text/html' ) ;
}

sub Headers
{
  my $self   = shift ;
  my $length = shift ;

  return $self->{'Headers'} if defined $self->{'Headers'} ;

  $self->codeFile() unless $self->{'length'} ;        # process uHTML to HTML
  $self->Finish()   unless $self->{'FinishRequest'} ; # Close the request, call all closing functions

  push @{$self->{'Headers'}}, 'x-powered-by',  'uHTML' ,
                              'Content-Length',$length || $self->{'length'} ,
                              'Content-Type',  $self->ContentType() . "; charset=$self->{'charset'}" ;

  push @{$self->{'Headers'}},'Set-Cookie',$self->{'SendCookie'}->{$_} foreach keys %{$self->{'SendCookie'}} ;

  return $self->{'Headers'} ;
}

sub setHeader
{
  my( $self,$name,$value ) = @_ ;

  $value = ' ' if $value eq '' ;
  push @{$self->{'Headers'}},$name,$value if $name ne '' ;
}

sub putHeader
{
  my $self = shift ;
  my $len  = shift ;
  my $H    = $self->Headers($len) ;

  for( my $i=0; $i<$#{$H}; $i+=2 ) { printf "%s: %s\n",$H->[$i],$H->[$i+1] }
  print "\n" ;
}

sub FileData
{
  my $self = shift ;

  unless( $self->{'FileData'} )
  {
    my   $FILE ;
    open $FILE,$self->file() or die "uHTML::request: $self->{'file'} not found" ;
    read $FILE,$self->{'FileData'},-s $FILE ;
  }
  return \$self->{'FileData'} ;
}

sub codeFile
{
  my $self = shift ;

  $self->Init() unless $self->{'InitRequest'} ; # Initialise the request and call all init functions
  $self->FileData() unless $self->{'FileData'} ;
  uHTML::fileStart( "$self->{'path'}/$self->{'File'}" ) ;
  $self->{'HTML'} = uHTML::recodedList( $self->{'FileData'},$self->{'ENV'} ) ;
  $self->{'length'} += length foreach @{$self->{'HTML'}} ;
  uHTML::fileEnd() ;
}

sub HTML
{
  my $self   = shift ;
  my $string = shift ;

  $self->codeFile() unless $self->{'length'} ;        # process uHTML to HTML
  return( $string ? join( '',@{$self->{'HTML'}} ) : $self->{'HTML'} ) ;
}

sub putFile
{
  my $self = shift ;

  $self->FileData() unless $self->{'FileData'} ;
  $self->codeFile() unless $self->{'length'} ;        # process uHTML to HTML
  print foreach $self->{'HTML'} ? @{$self->{'HTML'}} : $self->{'FileData'} ;
}

sub process
{
  my $self = shift ;
  my $env  = shift ;

  $self = uHTML::request->new( $env ) unless ref $self eq 'uHTML::request'; # get a new uHTML::request if needed
#   $self->Init() ; # Initialise the request and call all init functions
#   $self->codeFile() ; # process uHTML to HTML
#   $self->Finish() ; #Close the request call all closing functions
  $self->putHeader() ; # Send out headers
  $self->putFile() ;   # Send out HTML
}

sub home
{
  my $self = shift ;

  return $self->{'home'} ;
}


sub file
{
  my $self = shift ;

  return $self->{'file'} ;
}

sub File
{
  my $self  = shift ;
  my $fname = shift ;

  if( $fname )
  {
    $fname = "/${\($self->Path())}/$fname" unless $fname =~ m%^/% ;
    if( -f "${\($self->Root())}$fname" )
    {
      my $p0               = $self->{'Path'}->[0] ;
      $self->{'Path'}      = [ split m%/+%,$fname,-1 ] ;
      $self->{'File'}      = pop @{$self->{'Path'}} ;
      $self->{'BaseName'}  = $self->{'File'} =~ s/\.[^\.]*$//ir ;
      $self->{'path'}      = join '/',@{$self->{'Path'}} ;
      $self->{'file'}      = "${\($self->Root())}$self->{'path'}/$self->{'File'}" ;
      $self->{'Path'}->[0] = $p0 ;
    }
  }

  return $self->{'File'} ;
}

sub BaseName
{
  my $self = shift ;
  return $self->{'BaseName'} ;
}

sub RequestName
{
  my $self = shift ;
  return $self->{'RequestName'} ;
}

sub Path
{
  my $self = shift ;
  my $idx  = shift ;

  return $self->{'Path'}->[$idx] if $idx =~ m/^\d+$/ ;
  return (wantarray ? @{$self->{'Path'}}[$1 .. $2] : join '/',@{$self->{'Path'}}[$1 .. $2]) if $idx =~ m/^(\d+)(?:-|\.\.)(\d+)$/ ;
  return (wantarray ? @{$self->{'Path'}} : $self->{'path'}) ;
}

sub RequestPath
{
  my $self = shift ;
  my $idx  = shift ;

  return $self->{'Request'}->[$idx] if $idx =~ m/^\d+$/ ;
  return (wantarray ? @{$self->{'Request'}}[$1 .. $2] : join '/',@{$self->{'Request'}}[$1 .. $2]) if $idx =~ m/^(\d+)(?:-|\.\.)(\d+)$/ ;
  return (wantarray ? @{$self->{'Request'}} : $self->{'request'}) ;
}

sub Root
{
  my $self = shift ;

  $self->{'Root'} = shift if @_ ;
  return $self->{'Root'} ;
}

sub ServerPath
{
  my $self = shift ;
  my $Path = shift ;

  return $self->Root() unless $Path ne '' ;
  return( $Path=~s/^#// ? ($self->{'home'} && $Path !~ m%^/% ? "$self->{'home'}/$Path" : $Path) :
                          ($self->{'Root'}.(  $Path !~ m%^/% ? "$self->{'path'}/$Path" : $Path)) ) ;
}


1;

__END__

######################################
######################################

=pod

=encoding UTF-8

=head1 NAME

=over 2

=item B<uHTML::request> - B<HTTP> request handling

=back

=head1 VERSION

Version 1.81

=head1 DESCRIPTION

This library provides handling of B<HTTP> requests for B<uHTML>.
It pre-processes and normalizes B<HTTP-Request> variables
like e.g. path and directory names,
handles B<b>GET</b> and B<b>POST</b> data, handles cookies,
generates B<HTTP> headers and translates B<uHTML> in B<HTML>.

The probably most useful function of B<uHTML::request> is the invocation
of module specific functions before and after each request processing. This allows
other modules to process data provided with a B<HTTP-Request> before and after
the generation of B<HTML> code, allowing to alter the content of the B<HTML> content
and the B<HTTP> headers according to the data provided with the request.

=head1 REQUIREMENTS

This B<uHTML::request> library requires besides of the B<uHTML> library the libraries:
B<LWP::MediaTypes>, B<URI::Escape>, B<IO::Handle>, B<Time::Local> and B<POSIX>.

=head1 EXAMPLE

The following full working examples show the basic invocation of B<uHTML::request>.
For matching configurations, more file examples, B<uHTML> deployment details and
additional explanations see the B<uHTML> description.

=head2 uHTML::request with CGI

The first example addresses B<CGI> servers. The C<hook.pl> program must
be called by the webserver via a appropriate server request analogous to the basic
B<uHTML> invocation, e.g. by redirecting the requests in a C<.htaccess> file.

=head3 hook.pl

 #!/usr/bin/perl

 use strict;
 use uHTML::request;
 # $uHTML::FileName = '' ;  # uncomment for production code
 uHTML::request->process() ;

=head2 uHTML::request with FCGI

The second example addresses B<FCGI> servers. To simplify the
server deployment B<PSGI> with B<Plack> is used. B<Plack> expects
a B<perl> executable C<psgi> which follows the B<PSGI> specifications.
This executable takes the place of the C<hook.pl> in the first example.

=head3 psgi

 use strict;
 use uHTML::request;

 sub
 {
   my $env = shift ;

   $env->{'PATH_INFO'} = $env->{'URI'} ;  # nginx+PLACK needs it for the compability with Apache CGI
   # $uHTML::FileName = '' ;              # uncomment for production code

   my $request = uHTML::request->new( $env ) ;
   return [ 200,$request->Headers(),$request->HTML() ] if $request ;
   return [ 404,[ 'Content-Type' => 'text/plain' ],[ 'Not Found' ] ] ;
 }

The B<Plack> B<PSGI> server is started with C<plackup -s FCGI -S /tmp/uHTML -a /usr/lib/perl/*/uHTML/psgi>.
For the matching configuration of the B<nginx> server see the B<uHTML> description


B< >

=head1 Description of uHTML::request methods

B< >



=head2 new($env)

=head3 Overview


The method new creates a new uHTML::request object.

=head3 Parameters

=head4 $env

The optional parameter $env must refer to the environment hash associated with
the actuall B<HTTP> request. If missing, the current environment is used instead.

=head3 Example

 my $request = uHTML::request->new( $env );

=head2 Init(\&initFunc)

=head3 Overview


The method Init initialises the B<HTTP> request processing and calls all module specific init functions.

=head3 Parameters

=head4 &initFunc($request)

The parameter &initFunc must refer to a function which will be called
before the B<uHTML> file gets processed. The function is called with
the reference to the current B<uHTML::request> ($request). Typically
this function will process data sent to the website.

=head3 Example

 $request->Init(\&initFunc);

=head2 Finish(\&finishFunc)

=head3 Overview

The method Finish ends the B<HTTP> request processing and calls all module specific finish functions.

=head3 Parameters

=head4 &finishFunc($request)

The parameter &finishFunc must refer to a function which will
be called after the B<uHTML> file gets processed and before
the B<HTTP> headers get generated. The function is called
with the reference to the current B<uHTML::request> ($request).
Typically this function will finish processing of data sent to
the website, update server files and databases and set cookies
and data which will be sent to the browser.

=head3 Example

 $request->Finish(\&finishFunc);

=head2 ENV(B<>)

=head3 Overview

The method ENV returns the current environment.
By passing an argument the environment can be set as well,
this shouldn't be done except one knows very well what one does.


=head3 Example

 $env = $request->ENV();

=head2 QueryData($Name)

=head3 Overview

The method QueryData returns the query data associated with $Name,
speak data that was transmitted in the URI with the GET method.
It returns context depending either an array containing all values
associated with $Name in list context or the “first” value in scalar context.

=head3 Parameters

=head4 $Name

Name of the data.

=head3 Example

 $Data = $request->QueryData($DataName);

=head2 PostData($Name)

=head3 Overview

The method PostData returns the post data associated with $Name,
speak data that was transmitted with the POST method via STDIN.
It returns context depending either an array containing all values
associated with $Name in list context or the "first" value in scalar context.

When the data was transmitted as multipart/form-data the returned
value is a reference to a HASH (or and array of HASH references
in list context) containing the data. The HASH has the following values:

=over 6

=item name - name of the data

=item label - label provided with the data

=item length - data length

=item data - the data itself

=item boundary - boundary used in multipart/form-data

=back

=head3 Parameters

=head4 $Name

Name of the data.

=head3 Example

 $Picture = $request->PostData($PicName);

=head2 Data($Name)

=head3 Overview

The method Data returns a combination of post and query data associated with $Name,
speak data that was transmitted either with the GET or the POST method. It practically
lifts the difference between GET and POST data. It returns context depending either an
array containing all values associated with $Name in list context or the "first" value
in scalar context.

When the data was transmitted as multipart/form-data the returned value is a reference
to a HASH (or and array of HASH references in list context) containing the data.
The HASH has the following values:

=over 6

=item name - name of the data

=item label - label provided with the data

=item length - data length

=item data - the data itself

=item boundary - boundary used in multipart/form-data

=back

=head3 Parameters

=head4 $Name

Name of the data.

=head3 Example

 $Picture = $request->Data($PicName);

=head2 Cookie($Name,$Value,$expire,$path,$host,$JS)

=head3 Overview

The method Cookie reads and sets cookies. To set (or delete) a cookie $Value must be defined.

=head3 Parameters

=head4 $Name

Cookie name.

=head4 $Value

Cookie value. A value of "" do not removes the cookie.

=head4 $expire

Cookie expiration time in seconds (suffix none or s), hours (suffix h),
days (suffix d), months (suffix m), or years (suffix y). The value 0 deletes the cookie.

=head4 $path

Cookie path. If not defined the path "/" is used.

=head4 $host

The host associated with the cookie. If not defined, "$ENV{'SERVER_NAME'}" is used.

=head4 $JS

If true, then the cookie is available via JavaScript.

=head3 Example

 $Cookie = $request->Cookie($Name);

=head2 ContentType($Type)

=head3 Overview

The method ContentType returns the data type of the request file.
It relays rather on the name of the file than on the content.
Optionally the content type can be enforced by passing a parameter.

=head3 Parameters

=head4 $Type

The optional parameter $Type sets the content type used in the B<HTTP> headers.

=head3 Example

 $ContentType = $request->ContentType();

=head2 Headers($length)

=head3 Overview

The method Headers returns a reference to the B<HTTP> headers
in B<PSGI> format, a simple array, where the name and the value
of each header entry follow each other and the array consists
of value pairs.

=head3 Parameters

=head4 $length

If given it overrides the internally calculated length of the B<HTML> output.

=head3 Example

 $headers = $request->Headers();

=head2 putHeader($length)

=head3 Overview

The method putHeader sends the B<HTTP> headers to the STDOUT.

=head3 Parameters

=head4 $length

If given it overrides the internally calculated length of the B<HTML> output.

=head3 Example

 $request->putHeader();

=head2 setHeader($name,$value)

=head3 Overview

The method setHeader ads a B<HTTP> header.

=head3 Parameters

=head4 $name

Header name. Must be given.

=head4 $value

Header value. Is set to ' ' if missing.

=head3 Example

 $request->setHeader( 'x-PITarget',$request->Data('PITarget') );

=head2 FileData(B<>)

=head3 Overview

The method FileData gives access to the content of the B<uHTML> file.

=head3 Example

 $FData = $request->FileData();

=head2 codeFile(B<>)

=head3 Overview

The method codeFile translates internally B<uHTML> into B<HTML>.

=head3 Example

 $request->codeFile();

=head2 process($env)

=head3 Overview

The method process processes a B<CGI> B<HTTP> request and sends
the result to STDOUT. It can be either invoked as a method of
an existing request or as package function. In the latter
case process creates an own new B<uHTML::request> and uses
it to process the (CGI) B<HTTP> request .

=head3 Parameters

=head4 $env

The optional parameter $env is only used if a new B<uHTML::request>
is created. It must refer to the environment hash associated with
the actuall B<HTTP> request. If missing, the current environment
is used instead.

=head3 Example

 $request->process();
 uHTML::request->process( $env );

=head2 putFile(B<>)

=head3 Overview

The method putFile sends if existent the processed file content to STDOUT.
If the processed content is missing, it sends the original file to STDOUT.

=head3 Example

 $request->putFile();

=head2 file(B<>)

=head3 Overview

The method file returns the complete name including the path of the current request file.

=head3 Example

 $FName = $request->file();

=head2 File(B<>)

=head3 Overview

The method File returns the name of the current request file without the path .

=head3 Parameters

=head4 $name

Name of the new input file. If the $name starts with '/' the name is interpreted
as relative to the effective document directory $request->{'Root'}. Otherwise it
is interpreted as relative to the current directory. If the file is not found,
the parameter is ignored.

=head3 Example

 $FName = $request->File(/index.uhtml');

=head2  BaseName(B<>)

=head3 Overview

The method BaseName returns the name of the current file without the path and without extension.

=head3 Example

 $Name = $request->BaseName();

=head2 Path($idx)

=head3 Overview

The method Path returns the path of the current request.
It returns context depending either an array containing
the all path elements in list context or a string in scalar context.

=head3 Parameters

=head4 $idx

The optional parameter $idx indicates the desired part of the Path. It can contain a range.
The value 0 returns the name of the host.

=head3 Example

 $Path = $request->Path();

=head2 RequestPath($idx)

=head3 Overview

The method RequestPath returns the path used in the current B<HTTP> request.
It returns context depending either an array containing the all path elements
in list context or a string in scalar context.

=head3 Parameters

=head4 $idx

The optional parameter $idx indicates the desired part of the Path. It can contain a range.
The value 0 returns the name of the website.

=head3 Example

 $Site = $request->RequestPath(0);

=head2  RequestName(B<>)

=head3 Overview

The method RequestName returns the name of the file used
in the current request without the path and without extension.

=head3 Example

 $Name = $request->RequestName();

=head2 Root(B<>)

=head3 Overview

The method Root returns the current document directory.


=head3 Example

 $Docs = $request->Root();

=head2 ServerPath($Path)

=head3 Overview

The method ServerPath calculates the actual path on the server from a given $Path
according to the B<uHTML> path name conventions. Path names beginning with '/' are
considered as relative to DOCUMENT_ROOT. Path names not beginning with '/' and not
prefixed with '#' are considered as relative to the path of the current file.
Path names prefixed with '#' are considered as file system absolute if a '/' follows
the '#' and relative to DATA_ROOT (or the script directory) if no '/' follows the '#'.

=head3 Parameters

=head4 $Path

Path to convert.

=head3 Example

 $File = $request->ServerPath('/index.uhtml');

B<>

=head1 SEE ALSO

perl(1), http://www.uhtml.de/en/doc/request.uhtml, uHTML



=head1 AUTHOR

Roland Mosler (Roland.Mosler@Place.Ug)

=head1 COPYRIGHT

Copyright 2009 Roland Mosler.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


