package XMLRPC::PurePerl;

use strict;
use Data::Dumper;
use Exporter;
use LWP::UserAgent;
use HTTP::Request;

our $VERSION = "0.04";

=head1 XMLRPC::PurePerl

=head2 SYNOPSIS:
  my $client = new XMLRPC::PurePerl("http://127.0.0.1:8080/");
  my $result = $client->call("myMethod", { 'complex' => [ 'structure', 'goes' ] }, 'here' );
  
  my $xml = XMLRPC::PurePerl->encode_xmlrpc_call( $structure );
  my $str = XMLRPC::PurePerl->decode_xmlrpc( $xml );

  # In case you don't have XML::Simple loaded... (a simple XML serializer / de-serializer)

  my $var_xml = XMLRPC::PurePerl->encode_variable( $structure );
  my $var     = XMLRPC::PurePerl->decode_variable( $var_xml );

=head2 DESCRIPTION:

This module implements the XML-RPC standard as defined at www.xmlrpc.com and serves as a (de)serialization engine as well as a client for such services.

This module is in fairly close relation to an implementation that I wrote in javascript.  The main problem I ran into web services and browsers was the dependence on the built in javascript XML parser.  This module shows off how rolling your own can give you a bit of a boost in performance as well as avoiding dependencies for a compiled XML parser (for you guys who work in the DOD arena like me).  If I had more time, I'd have rolled my own basic LWP modules just to avoid the extra dependencies.  Anyway, this client provides the basic functionality that modules like RPC::XML or Frontier::RPC2 provide, the only difference is being the reason for the name, this is a pure perl implementation.

=head2 DATATYPES:

You can override the basic data types that perl will interpret by instantiating type objects.  You simply pass the value as the sole argument, and it will transform into the appropriate XML upon serialization.  Three data types will remain as type objects during de-serialization: datetime, base64 and boolean.  More simply, date objects returned from the server will come back as a blessed reference of "XMLRPC::PurePerl::Type::datetime".  All of the type modules contain simple "value" methods to pull the value from the blessed hash reference.  

There are also some simple static methods on XMLRPC::PurePerl to generate these structures.

Lastly, the datetime constructur was given some flexibility.  Instead of adding a full date parser, I wrote a few a regex's to parse out most of the sane date formats and put together the XMLRPC date format.  Below are some examples of the acceptable formats..

  # Examples:

  my $boolean = XMLRPC::PurePerl->boolean(1);
  my $string  = XMLRPC::PurePerl->string(12345);
  my $b64     = XMLRPC::PurePerl->base64("AB91231=");
  my $double  = XMLRPC::PurePerl->double(123.456);
  my $date    = XMLRPC::PurePerl->datetime("6 June 2006");

  my $value = $b64->value(); # example of using the value method for these data types

  # Acceptable date formats. (times are optional)

  # 20050701 
  # 2004/04/22    (dashes, spaces or hyphens)
  # SEP 19, 2003 
  # 04-22-2004    (dashes, hyphens or spaces)
  # 30 July 05
  # July 30 2005 

  # 20001109171200
  # {ts '2003-06-23 12:21:43'}
  # 302100ZSEP1998
  # 2001-01-01T05:22:23.000Z

Any of the first six formats can also have a time on the end.  Here's the acceptable formats for time.

  # 00:00
  # 00:00:00
  # 00:00 AM  (space optional)
  # 00:00:00 AM 

=item Fault

Faults are represented as an object as well, with a signature of XMLRPC::PurePerl::Type::Fault.  The parser allows the fault param structure open to any data type, so if your server decides to send a complex structure back with the fault, it will deserialize it appropriately.

=cut

# this will set up our simple data type wrappers
BEGIN {
  foreach my $pkg ( qw(i4 string boolean base64 double) ) {
    eval ( "package XMLRPC::PurePerl::Type::$pkg;\nsub new { return bless( { 'type' => '$pkg', 'val' => \$_[1] } ); }\nsub value { return (shift)->{'val'}; } " );
  }
}

our @ISA = qw(Exporter);
# be polite! allow these to be imported, but don't enforce import
our @EXPORT_OK = qw(encode_call_xmlrpc encode_response_xmlrpc decode_xmlrpc encode_variable decode_variable);

# entity hash so I don't have to import HTML::Entities
our %entities = (
  '<' => '&lt;',
  '>' => '&gt;',
  '&' => '&amp;',
  '"' => '&quot;',
); 
our %reverse_entities = reverse(%entities); # reverse it for the decode

# These are the primary regex's used for parsing an XML document (probably need optimized a bit more)
my $scalarRgx   = qr/^(?:string|i4|int|double)>([^<]+)/im;
my $memberRgx   = qr/^name>([^<]+)/im;
my $valRgx      = qr/^value>([^<]+)<\/value$/im;
my $boolRgx     = qr/^boolean>([^<]+)/im;
my $b64Rgx      = qr/^base64>([^<]+)/im;
my $dateRgx     = qr/^[^>]+>([0-9]{4}[0-9]{2}[0-9]{2}T[0-9]{2}\:[0-9]{2}\:[0-9]{2})<[^<]+$/;
my $startString = qr/^(string|i4|int|double)/i;
my $startDate   = qr/^(?:datetime|datetime.iso8601)/i;

sub _entity_encode { # private method for encoding entities
  my $val = shift;
  $val =~ s/([&<>\"])/$entities{$1}/ge;
  $val;
}
sub _entity_decode { # private entites for decoding entities
  my $val = shift;
  $val =~ s/(&lt;|&gt;|&amp;|&quot;)/$reverse_entities{$1}/ge;
  $val;
}

=head2 Constructor

  my $client = new XMLRPC::PurePerl("http://validator.xmlrpc.com");

Simply pass the fully qualified URL as your argument to the constructor, and off you go.  

=cut

sub new {
  my ( $class, $url ) = @_ ;

  my $this = {
    'lwp' => new LWP::UserAgent(),
    'request' => HTTP::Request->new( 
      'POST', $url, new HTTP::Headers( 'Content-Type' => 'text/xml' ) 
    )
  };
  return bless($this);
}

=head2 call

  my $result = $client->call("method", "argumunts");

First argument to the call method is the method you wish to call, the rest will constitute the values that populate "<params>".  Each one will serialize into a "<param>" entry.  

=cut

sub call {
  my $self = shift;
  die("Instantiate this class to call this method...") if ( ref($self) !~ /^XMLRPC::PurePerl/ );

  my $xml = &encode_call_xmlrpc(@_);
  $self->{'request'}->content($xml);
  my $res = $self->{'lwp'}->request( $self->{'request'} );

  die $res->status_line() unless ( $res->is_success() ); # for HTTP failure

  return &decode_xmlrpc( $res->content() ); # don't die on fault
}

=head2 encode_call_xmlrpc

  my $xml = XMLRPC::PurePerl->encode_call_xmlrpc("methodName", "arguments");

This, will generate an XMLRPC request xml document based on the arguments passed to it.

=cut

sub encode_call_xmlrpc {
  shift if ( $_[0] eq 'XMLRPC::PurePerl' );
  my $method = shift;
  my $xml = "<?xml version=\"1.0\"?>\n<methodCall>\n<methodName>$method</methodName>\n<params>\n";
  
  foreach my $struct ( @_ ) {
    $xml .= "<param>\n";
    &encode_variable($struct, \$xml);
    $xml .= "</param>\n";
  }
  $xml .= "</params>\n</methodCall>\n";
  return $xml;
}

=head2 encode_response_xmlrpc

  my $xml = XMLRPC::PurePerl->encode_response_xmlrpc("arguments");

This, will generate an XMLRPC response xml document based on the arguments passed to it.

=cut

sub encode_response_xmlrpc {
  shift if ( $_[0] eq 'XMLRPC::PurePerl' );
  my $method = shift;
  my $xml = "<?xml version=\"1.0\"?>\n<methodResponse>\n<params>\n";
  
  foreach my $struct ( @_ ) {
    $xml .= "<param>\n";
    &encode_variable($struct, \$xml);
    $xml .= "</param>\n";
  }
  $xml .= "</params>\n</methodResponse>\n";
  return $xml;

}

=head2 encode_variable

  my $xml = XMLRPC::PurePerl->encode_variable("arguments");

I'm a huge fan of XML::Simple, but having to remember all the options, and taking account for "force_array" to set values as array references instead of simple scalars (where you only have one value coming back is annoying.  I have consistently ran into problems when my "simple" usage grew into more complex usage over time.  This simple function solves this for, well, me at least.  

=cut

sub encode_variable {
  shift if ( $_[0] eq 'XMLRPC::PurePerl' );
  my ( $obj, $xml ) = @_; 
  my $ref = ref($obj);

  if ( ! $ref ) {
    if ( $obj =~ /^\-?[0-9]+\.[0-9]*$/ ) {
      ${$xml} .= "<value><double>$obj</double></value>\n";
    } elsif ( $obj =~ /^-?[0-9]+$/ ) {
      ${$xml} .= "<value><i4>$obj</i4></value>\n";
    } else {
      ${$xml} .= "<value><string>" . &_entity_encode($obj) . "</string></value>\n";
    }
  } elsif ( $ref eq 'ARRAY' ) {
    ${$xml} .= "<value><array><data>\n";
    foreach my $val ( @{$obj} ) {
      &encode_variable($val, $xml);
    }
    ${$xml} .= "</data></array></value>\n";
  } elsif ( $ref eq 'HASH' ) {
    ${$xml} .= "<value><struct>\n";
    foreach my $key ( keys(%{$obj}) ) {
      ${$xml} .= "<member><name>" . &_entity_encode($key) . "</name>"; 
      &encode_variable( $obj->{$key}, $xml ); 
      ${$xml} .= "</member>\n";
    }
    ${$xml} .= "</struct></value>\n";
  } elsif ( $ref =~ /^XMLRPC::PurePerl::Type::(.+)$/ ) {
    if ( $1 eq 'datetime' ) {
      ${$xml} .= "<value><dateTime.iso8601>" . $obj->value() . "</dateTime.iso8601></value>\n";
    } else {
      ${$xml} .= "<value><$1>" . $obj->value() . "</$1></value>";
    }
  } elsif ( $ref eq "CODE" ) { 
    die("Cannot serialize a subroutine!"); 
  }
}

=head2 decode_variable

  my $structure = XMLRPC::PurePerl->decode_variable("arguments");

The deserializer of the previously mentioned function.  

=cut

sub decode_variable {
  shift if ( $_[0] eq 'XMLRPC::PurePerl' );
  my $xml = shift;
  my @tokens;
  if ( ref($xml) eq 'ARRAY' ) {
    @tokens = @{$xml};
  } else {
    $xml =~ s/([<>])\s*/$1/g;
    $xml =~ s/>\n/>/g;
    @tokens = split("><", $xml);
  }
  my $position = 1;
  my @outbound;

  until ( $position == scalar(@tokens) ) {
    if ( $tokens[$position] =~ $startString ) {
      my $ob = ($tokens[$position] =~ $scalarRgx)[0];
      push(@outbound, $ob);
    } elsif ( lc($tokens[$position]) eq 'struct' ) {
      my $ob = {};
      &parse_struct($ob, \@tokens, \$position);
      push(@outbound, $ob);
    } elsif ( lc($tokens[$position]) eq 'array' ) {
      my $ob = [];
      &parse_array($ob, \@tokens, \$position);
      push(@outbound, $ob);
    } elsif ( $tokens[$position] =~ $startDate ) {
      my $ob = ($tokens[$position] =~ $dateRgx)[0];
      push(@outbound, XMLRPC::PurePerl::Type::datetime->new($ob));
    } elsif ( lc($tokens[$position]) =~ $boolRgx ) {
      push(@outbound, XMLRPC::PurePerl::Type::boolean->new($1));
    } elsif ( lc($tokens[$position]) =~ $b64Rgx ) {
      push(@outbound, XMLRPC::PurePerl::Type::base64->new($1));
    } else {
    }
    $position++;
  }
  if ( scalar(@outbound) == 1 ) {
    return $outbound[0];
  } else {
    if ( wantarray ) {
      return @outbound;
    } else {
      return \@outbound;
    }
  }
}

=head2 decode_xmlrpc

  my $structure = XMLRPC::PurePerl->decode_xmlrpc();
  if ( ref($structure) =~ /fault/i ) {
    &do_something_to_handle_the_fault( $structure->value() );
  }

The data structure returned will be in scalar context, or in list context, depending on your lvalue's sigil.
If you're decoding a methodCall, you'll get a structure keyed by the methodName and the arguments passed to it as an array reference..

  # If you dumped out the de-serialization of a methodCall XML document
  $VAR1 = {
    'method' => 'myMethod'
    'args' => [ 'a', 'b', 'c' ]
  }

=cut

sub decode_xmlrpc {
  shift if ( $_[0] eq 'XMLRPC::PurePerl' );
  my $xml = shift;
  $xml =~ s/([<>])\s*/$1/g;
  $xml =~ s/>\n/>/g;
  my @tokens = split("><", $xml);

  if ( $xml =~ /<fault>/ ) {
    shift(@tokens) until ( $tokens[0] eq 'value' ); # whittle!
    pop(@tokens)   until ( $tokens[$#tokens] eq '/value' );
    return XMLRPC::PurePerl::Fault->new( &decode_variable( \@tokens ) );
  }

  my $methodName;
  my $position; 
  if ( $tokens[1] eq 'methodCall' ) { 
    $position = 6;
    $tokens[2] =~ />([^>]+)</;
    $methodName = $1;
  } else {
    $position = 5;
  }
  my @outbound;

  until ( $position == scalar(@tokens) ) {
    if ( $tokens[$position] =~ $startString ) {
      my $ob = ($tokens[$position] =~ $scalarRgx)[0];
      push(@outbound, $ob);
    } elsif ( lc($tokens[$position]) eq 'struct' ) {
      my $ob = {};
      &parse_struct($ob, \@tokens, \$position);
      push(@outbound, $ob);
    } elsif ( lc($tokens[$position]) eq 'array' ) {
      my $ob = [];
      &parse_array($ob, \@tokens, \$position);
      push(@outbound, $ob);
    } elsif ( $tokens[$position] =~ $startDate ) {
      my $ob = ($tokens[$position] =~ $dateRgx)[0];
      push(@outbound, XMLRPC::PurePerl::Type::datetime->new($ob));
    } elsif ( lc($tokens[$position]) =~ $boolRgx ) {
      push(@outbound, XMLRPC::PurePerl::Type::boolean->new($1));
    } elsif ( lc($tokens[$position]) =~ $b64Rgx ) {
      push(@outbound, XMLRPC::PurePerl::Type::base64->new($1));
    } else { 
    }
    $position++;
  }
  if ( scalar(@outbound) == 1 ) { # Only 1 "param" in responses
    return $outbound[0];
  } else {
    if ( wantarray ) {
      return @outbound;
    } elsif ( $methodName ) {
      return {
        'method' => $methodName,
        'args' => \@outbound
      }
    } else { # for decoding methodCall xml files...
      return \@outbound;
    }
  }
}

# internal function for parsing arrays
sub parse_array {
  my ( $structure, $tokens, $position ) = @_; 
  my $currentElement = 0;

  ${$position} += 2;

  for ( undef; ${$position}..scalar(@{$tokens}); ${$position}++ ) {
    if ( $tokens->[${$position}] eq 'value' ) {
      ${$position}++;
      if ( $tokens->[${$position}] =~ $startString ) {
        $structure->[$currentElement++] = &_entity_decode(($tokens->[${$position}] =~ $scalarRgx)[0]);
      } elsif ( lc($tokens->[${$position}]) eq 'struct' ) {
        my $outbound = {};
        &parse_struct($outbound, $tokens, $position);
        $structure->[$currentElement++] = $outbound;
      } elsif ( lc($tokens->[${$position}]) eq 'array' ) {
        my $outbound = [];
        &parse_array($outbound, $tokens, $position);
        $structure->[$currentElement++] = $outbound;
      } elsif ( $tokens->[${$position}] =~ $startDate ) {
        my $dt = ($tokens->[${$position}] =~ $dateRgx)[0];
        $structure->[$currentElement++] = XMLRPC::PurePerl->datetime($dt);

      } elsif ( $tokens->[${$position}] =~ $boolRgx ) {
        $structure->[$currentElement++] = XMLRPC::PurePerl->boolean( $1 );
      } elsif ( $tokens->[${$position}] =~ $b64Rgx ) {
        $structure->[$currentElement++] = XMLRPC::PurePerl->base64( $1 );
      } else {
      }
    } elsif ( $tokens->[${$position}] =~ $valRgx ) { # is it a value
      $structure->[ $currentElement++ ] = &_entity_encode($1);
    } elsif ( $tokens->[${$position}] eq '/data' ) {
      return;
    } else {
    }
  }
}

# internal function for parsing strcutures
sub parse_struct {
  my ( $structure, $tokens, $position, $currentKey ) = @_;

  for ( undef; ${$position}..scalar(@{$tokens}); ${$position}++ ) {
    if ( lc($tokens->[${$position}]) eq 'member' ) {
      ${$position}++;
      $currentKey = ($tokens->[${$position}] =~ $memberRgx)[0];
      ${$position}++;

      if ( $tokens->[${$position}] =~ $valRgx ) { # is it a value
        $structure->{$currentKey} = ($tokens->[${$position}] =~ $valRgx)[0];

      } else { # increment by one and retest
        ${$position}++;

        if ( $tokens->[${$position}] =~ $startString ) {
          $structure->{$currentKey} = &_entity_decode(($tokens->[${$position}] =~ $scalarRgx)[0]);

        } elsif ( $tokens->[${$position}] eq 'struct' ) {
          my $outbound = {};
          &parse_struct($outbound, $tokens, $position);
          $structure->{$currentKey} = $outbound;

        } elsif ( $tokens->[${$position}] eq 'array' ) {
          my $outbound = [];
          &parse_array($outbound, $tokens, $position);
          $structure->{$currentKey} = $outbound;

        } elsif ( $tokens->[${$position}] =~ $startDate ) {

          my $dt = ($tokens->[${$position}] =~ $dateRgx)[0];
          $structure->{$currentKey} = XMLRPC::PurePerl->datetime($dt);

        } elsif ( $tokens->[${$position}] =~ $boolRgx ) {
          $structure->{$currentKey} = XMLRPC::PurePerl->boolean( $1 );
        } elsif ( $tokens->[${$position}] =~ $b64Rgx ) {
          $structure->{$currentKey} = XMLRPC::PurePerl->base64( $1 );
        } else {
        }
      }
    } elsif ( lc($tokens->[${$position}]) eq '/struct' ) {
      return;
    }
  }
}

# sometimes I forget i4 == int
sub int {
  shift if ( $_[0] =~ /^XMLRPC::/ );
  return XMLRPC::PurePerl::Type::i4->new( $_[0] );
}
sub date {
  shift if ( $_[0] =~ /^XMLRPC::/ );
  return XMLRPC::PurePerl::Type::datetime->new( shift );
}
sub datetime {
  shift if ( $_[0] =~ /^XMLRPC::/ );
  return XMLRPC::PurePerl::Type::datetime->new( shift );
}

# generate a helper static subroutine for each data type
foreach my $pkg ( qw(i4 string boolean base64 double) ) {
  eval ( "sub $pkg { shift if ( \$_[0] =~ /^XMLRPC::/ ); return new XMLRPC::PurePerl::Type::$pkg( shift, '$pkg' ); }" );
}

package XMLRPC::PurePerl::Type::datetime;

our %month_struct = (
  "JAN" => "01", "FEB" => "02", "MAR" => "03", "APR" => "04", "MAY" => "05", "JUN" => "06", "JUL" => "07", "AUG" => "08", "SEP" => "09", "OCT" => "10", "NOV" => "11", "DEC" => "12", "01" => "JAN", "02" => "FEB", "03" => "MAR", "04" => "APR", "05" => "MAY", "06" => "JUN", "07" => "JUL", "08" => "AUG", "09" => "SEP", "10" => "OCT", "11" => "NOV", "12" => "DEC", "JANUARY" => "01", "FEBRUARY" => "02", "MARCH" => "03", "APRIL" => "04", "MAY" => "05", "JUNE" => "06", "JULY" => "07", "AUGUST" => "08", "SEPTEMBER" => "09", "OCTOBER" => "10", "NOVEMBER" => "11", "DECEMBER" => "12"
);

# 20050701 , 20050701 00:00:00 , 20050701 00:00:00PM , 2004/04/22 , 2004/22/02 00:00 
my $ymd  = qr/^([0-9]{4})[\/\-\s]?([0-9]{2})[\/\-\s]?([0-9]{1,2})[T\s]?([0-9]{2})?(\:[0-9]{2}\:?(?:[0-9]{2})?)?[\s]?([AP]M)?$/i;
# SEP 19, 2003 09:45:00
my $Mdy  = qr/^([A-Za-z]{3})\s(0?[1-9]|1[0-9]|2[0-9]|3[0-1]),?\s?([0-9]{4})\s*([0-9]{2})?(\:[0-9]{2}\:?(?:[0-9]{2})?)?\s?([AP]M)?$/i;
# 04-22-2004 , 04-22-2004 00:00AM, 04-22-2004 , 04-22-2004 00:00:00AM
my $mdy  = qr/^(0?[1-9]|1[0-2])[\/\-\\s](0?[1-9]|1[0-9]|2[0-9]|3[0-1]|[1-9])[\/\-\\s]([0-9]{4})[\sT]?([0-9]{2})?(\:[0-9]{2}\:?(?:[0-9]{2})?)?\s?([AP]M)?$/i;
# 30 July 05
my $dmy  = qr/^(0?[1-9]|1[0-9]|2[0-9]|3[0-1])\s*([A-Za-z]{1,9})\s?([0-9]{2,4})\s*([0-9]{2})?(\:[0-9]{2}\:?(?:[0-9]{2})?)?[\sT]?([AP]M)?$/i;
# July 30 2005 16:17 or July 30, 2005 16:17
my $MONTHdy = qr/^([A-Za-z]{1,9})\s?(0?[1-9]|1[0-9]|2[0-9]|3[0-1])[\s,]([0-9]{2,4})[\sT]?([0-9]{2})?(\:[0-9]{2}\:?(?:[0-9]{2})?)?\s?([AP]M)?$/i;
# 20001109171200
my $allnum = qr/^([0-9]{4})(0?[0-9]|1[0-2])(0?[1-9]|1[0-9]|2[0-9]|3[0-1])([0-9]{2})([0-9]{2})([0-9]{2})$/;
# {ts '2003-06-23 12:21:43'}
my $mssql = qr/\{ts '([0-9]{4})\-(0?[0-9]|1[0-2])\-(0?[1-9]|1[0-9]|2[0-9]|3[0-1])\s([0-9]{2})\:([0-9]{2})\:([0-9]{2})'\}/i;
# 302100ZSEP1998
my $dtg = qr/^(0?[1-9]|1[0-9]|2[0-9]|3[0-1])([0-9]{2})([0-9]{2})[A-Z]([A-Za-z]{3})([0-9]{2,4})$/i;
# 2001-01-01T05:22:23.000Z
my $prs = qr/^[0-9]{4}\-?[0-9]{2}\-?[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}/;

# TODO: make single digit hours valid in the regex, auto pad the 0.. (thought about using printf, but it wouldn't handle AM/PM)

sub new {
  my ( $class, $date ) = @_;
  my $this = { 'type' => 'datetime' };

  # Quick commentary on why there is a huge if/elsif block here for parsing dates..
  # Date::Manip, Date::Parse, Date::Calc are all modules that I COULD have used for parsing "common"
  # date formats.. I wanted to avoid adding the dependency, and I really just needed to get to the XMLRPC
  # format more than anything...
  # 19980717T14:08:55 is an example of the format we're after...

  if ( my ( $year, $month, $day, $hour, $minsec, $ampm ) = $date =~ $ymd ) { # 20050701 , 20050701 00:00:00 , 20050701 00:00:00PM , 2004/04/22 , 2004/22/02 00:00 
    $hour   ||= '00';
    $minsec ||= ':00:00';
    $ampm   ||= '';
    $this->{'val'} = ( length($year) == 2 ? '20' . $year : $year )  . $month . sprintf("%02d", $day) . 'T' .  ( $hour ? ( $ampm eq 'PM' ? 12 + $hour : $hour ) . ( length($minsec) == 3 ? $minsec . ':00' : $minsec ) : '00:00:00' );

  } elsif ( $date =~ $prs ) { # 2001-01-01T05:22:23.000Z
    $this->{'val'} = $date;
    $this->{'val'} =~ s/\-//g;
    $this->{'val'} =~ s/\..*$//;

  } elsif ( my ($Mdy_month, $Mdy_day, $Mdy_year, $Mdy_hour, $Mdy_minsec, $Mdy_ampm) = $date =~ $Mdy ) { # SEP 19, 2003 09:45:00
    $Mdy_hour   ||= '';
    $Mdy_minsec ||= '';
    $Mdy_ampm   ||= '';
    $this->{'val'} = $Mdy_year . $month_struct{uc($Mdy_month)} . sprintf("%02d", $Mdy_day) . 'T' . ( $Mdy_hour ? ( $Mdy_ampm eq 'PM' ? 12 + $Mdy_hour : $Mdy_hour ) . ( length($Mdy_minsec) == 3 ? $Mdy_minsec . ':00' : $Mdy_minsec ) : '00:00:00' );

  } elsif ( my ($mdy_month, $mdy_day, $mdy_year, $mdy_hour, $mdy_minsec, $mdy_ampm) = $date =~ $mdy ) { # 04-22-2004 , 04-22-2004 00:00AM, 04-22-2004 , 04-22-2004 00:00:00AM
    $mdy_hour   ||= '';
    $mdy_minsec ||= '';
    $mdy_ampm   ||= '';
    $this->{'val'} = $mdy_year . $mdy_day . sprintf("%02d", $mdy_month) . 'T' .  ( $mdy_hour ? ( $mdy_ampm eq 'PM' ? 12 + $mdy_hour : $mdy_hour ) . ( length($mdy_minsec) == 3 ? $mdy_minsec . ':00' : $mdy_minsec ) : '00:00:00' );

  } elsif ( $date =~ $dtg ) { # 2001-01-01T05:22:23.000Z
    $this->{'val'} = ( length($5) == 2 ? '20' . $5 : $5 ) .  $month_struct{uc($4)} . $1 . 'T' . "$2:$3:00";

  } elsif ( $date =~ $dmy ) { # 30 July 05
    $this->{'val'} = ( length($3) == 2 ? '20' . $3 : $3 ) . $month_struct{uc($2)} . sprintf("%02d", $1) . 'T' . ( $4 ? ( $6 eq 'PM' ? 12 + $4 : $4 ) . ( length($5) == 3 ? $5 . ':00' : $5 ) : '00:00:00' );

  } elsif ( $date =~ $MONTHdy ) { # July 30 2005 16:17 or July 30, 2005 16:17
    $this->{'val'} = ( length($3) == 2 ? '20' . $3 : $3 ) .  $month_struct{uc($1)} . sprintf("%02d", $2) . 'T' . ( $4 ? ( $6 eq 'PM' ? 12 + $4 : $4 ) . ( length($5) == 3 ? $5 . ':00' : $5 ) : '00:00:00' );

  } elsif ( $date =~ $allnum ) { # 20001109171200
    $this->{'val'} = $1 . $2 . $3 . 'T' . $4 . ':' . $5 . ':' . $6;

  } elsif ( $date =~ $mssql ) { # {ts '2003-06-23 12:21:43'}
    $this->{'val'} = $1 . $2 . $3 . 'T' . $4 . ':' . $5 . ':' . $6;

  } else {
    warn "Date Format $date unknown...";
    $this->{'val'} = undef;
  }
  return bless( $this );
}

sub value {
  return (shift)->{'val'};
}

package XMLRPC::PurePerl::Fault;

sub new {
  my ( $class, $this ) = @_;
  return bless( $this );
}

sub value { return shift; }

=head1 WHY DO THIS!?!

Yeah, there's a bunch of these modules out there for this kind of stuff.  I in no way mean to step on anyones toes, but I am quite proud of the benchmarks that this module is capable of producing.  It does have it's limits, but for such a lightweight little engine, I think it does fairly well for itself.  Let's keep in mind that this engine is a "fast and loose" engine, with very little in terms of defense from malformed XML, which RPC::XML and Frontier have more built in defense through the use of a true XML Parser.  

  500 elements
  ENCODING SPEED TEST
  Benchmark: running frontier, pureperl, rpcxml for at least 10 CPU seconds...
    frontier: 11 wallclock secs (10.47 usr +  0.09 sys = 10.56 CPU) @ 26.70/s (n=282)
    pureperl: 10 wallclock secs (10.69 usr +  0.03 sys = 10.72 CPU) @ 86.75/s (n=930)
      rpcxml: 11 wallclock secs (10.55 usr +  0.05 sys = 10.59 CPU) @ 66.93/s (n=709)
  DECODING SPEED TEST
  Benchmark: running frontier, pureperl, rpcxml for at least 10 CPU seconds...
    frontier: 11 wallclock secs (10.64 usr +  0.02 sys = 10.66 CPU) @ 10.51/s (n=112)
    pureperl: 11 wallclock secs (10.50 usr +  0.08 sys = 10.58 CPU) @ 14.65/s (n=155)
      rpcxml: 11 wallclock secs (10.58 usr +  0.03 sys = 10.61 CPU) @  6.69/s (n=71)

  1000 elements
  ENCODING SPEED TEST
  Benchmark: running frontier, pureperl, rpcxml for at least 10 CPU seconds...
    frontier: 10 wallclock secs (10.44 usr +  0.11 sys = 10.55 CPU) @ 11.95/s (n=126)
    pureperl: 10 wallclock secs (10.55 usr +  0.00 sys = 10.55 CPU) @ 43.61/s (n=460)
      rpcxml: 10 wallclock secs (10.50 usr +  0.09 sys = 10.59 CPU) @ 29.92/s (n=317)
  DECODING SPEED TEST
  Benchmark: running frontier, pureperl, rpcxml for at least 10 CPU seconds...
    frontier: 10 wallclock secs (10.08 usr +  0.00 sys = 10.08 CPU) @  5.26/s (n=53)
    pureperl: 11 wallclock secs (10.27 usr +  0.08 sys = 10.34 CPU) @  7.35/s (n=76)
      rpcxml:  9 wallclock secs (10.19 usr +  0.00 sys = 10.19 CPU) @  3.34/s (n=34)

  5000 elements (beyond this, PurePerl isn't the best module to use)
  ENCODING SPEED TEST
  Benchmark: running frontier, pureperl, rpcxml for at least 10 CPU seconds...
    frontier: 11 wallclock secs (10.81 usr +  0.05 sys = 10.86 CPU) @  1.10/s (n=12)
    pureperl: 10 wallclock secs ( 9.98 usr +  0.08 sys = 10.06 CPU) @  8.55/s (n=86)
      rpcxml: 10 wallclock secs (10.16 usr +  0.19 sys = 10.34 CPU) @  2.22/s (n=23)
  DECODING SPEED TEST
  Benchmark: running frontier, pureperl, rpcxml for at least 10 CPU seconds...
    frontier: 10 wallclock secs (10.48 usr +  0.00 sys = 10.48 CPU) @  1.05/s (n=11)
    pureperl: 11 wallclock secs ( 9.31 usr +  0.94 sys = 10.25 CPU) @  0.88/s (n=9)
      rpcxml: 11 wallclock secs (10.45 usr +  0.03 sys = 10.48 CPU) @  0.67/s (n=7)

=head1 See also:

  RPC::XML (the best XMLRPC module out there for exacting precision of the specification)
  Frontier::RPC2 (the reference implementation)
  SOAP::Lite, XMLRPC::Lite (my quest will soon become conquering Document Literal (why is this so hard to do in Perl still?)

=head1 Acknowledgements:

Dave Winer, thanks for such a great protocol
Paul Lindner and Randy Ray (thanks for the kudos in your book "Programming Web Services in Perl"!), my former co-workers at Red Hat.
Joshua Blackburn, who pushed me to write the original javascript implementation of this module.
Claus Brunzema, for a very polite bug report dealing with negative integers!
Frank Rothhaupt, for a very polite bug report dealing with fault's!

=head1 COPYRIGHT:

The XMLRPC::PurePerl module is Copyright (c) 2006 Ryan Alan Dietrich. The XMLRPC::PurePerl module is free software; you can redistribute it and/or modify it under the same terms as Perl itself with the exception that it cannot be placed on a CD-ROM or similar media for commercial distribution without the prior approval of the author.

=head1 AUTHOR:

XMLRPC::PurePerl by Ryan Alan Dietrich <ryan@dietrich.net>

=cut

1;
