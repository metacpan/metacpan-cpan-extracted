package VSGDR::UnitTest::TestSet::Resx;

use 5.010;
use strict;
use warnings;


#our \$VERSION = '1.01';


use parent qw(Clone) ;

use XML::Simple;
use XML::Quote qw(:all);

use Data::Dumper ;
use Carp ;

use vars qw($AUTOLOAD);


#TODO: 1. Fix more stuff for vs2010 gdr tests.


sub new {

    local $_ = undef ;

    my $invocant         = shift ;
    my $class            = ref($invocant) || $invocant ;

    my @elems            = @_ ;
    my $self             = bless {}, $class ;

    $self->_init(@elems) ;
    return $self ;
}


sub _init {

    local $_ = undef ;

    my $self                = shift ;
    my $class               = ref($self) || $self ;
    return ;

}

sub scripts {
    my $self       = shift or croak 'no self';
    my $scripts ;
    $scripts       = shift if @_;
    if ( defined $scripts ) {
        $self->{SCRIPTS} = $scripts ;
    }
    return $self->{SCRIPTS} ;
}


## ======================================================
sub serialise {
    my $self        = shift or croak 'no self' ;
    my $file        = shift or croak 'no file' ;
    my $object      = shift or croak 'no object';
    
    my $code        = $self->deparse($object);    
    
    my $data;
    my $fh = new IO::File "> ${file}" ;
    if (defined ${fh} ) {
        print ${fh} $code;
        $fh->close;
    }
    else {
        croak "Unable to write to ${file}.";
    }
    return ;
}
## ======================================================
sub deserialise {

    my $self        = shift or croak 'no self' ;
    my $file        = shift or croak 'no file' ;
    my $data;
    my $fh = new IO::File;
    if ($fh->open("< ${file}")) {
        { local $/ = undef ; $data = <$fh> ; }     
        $fh->close;
    }
    else {
        croak "Unable to read from ${file}.";
    }
    my $object    = $self->parse($data);
    return ${object} ;
}
## ======================================================


sub parse {

    my $self    = shift or croak 'no self' ;
    my $code    = shift ;

    if ( defined $code ) {
        my $ref = XMLin($code,ForceArray=>['data'] );
        my %res = () ;
        foreach my $k ( keys %{$ref->{data}} ) {
            ( my $newKey = $k ) =~ s{\.SqlScript$}{}x ;
            if ( ref($ref->{data}->{$k}->{value}) ne 'HASH' ) {
                $res{$newKey} = $ref->{data}->{$k}->{value} ;
            } 
            else {
#                warn 'Something strange with XMLin again' ;
            }
        }
        $self->{SCRIPTS} = \%res ;
    }; 
    
    return $self->{SCRIPTS} ;
}

sub deparse {
    my $self    = shift or croak 'no self' ;
    my $code    = shift ;

    return $self->xmlHeader() .
           $self->xmlTests($self->{SCRIPTS}) .
           $self->xmlFooter() ;

}

sub xmlTests {
    my $self    = shift or croak 'no self' ;
    my $resSet  = shift or croak 'no resources' ;   # ref to a has containing test name - sql pairs

    my $result     = "" ;

    foreach my $k ( keys %$resSet) {
    $result .= '  <data name="' . $k . '.SqlScript" xml:space="preserve">'. "\n";
#    $result .= "    <value>\n" ;
    $result .= "    <value>" ;
    $result .= xml_quote_min($$resSet{$k}) ;
#    $result .= xml_quote($$resSet{$k}) ;
    $result .= "</value>\n" ; 
    $result .= "  </data>\n" ;
    }
    return $result ;
}

sub xmlHeader {
    my $self        = shift or croak 'no self' ;
return <<'EOH';
<?xml version="1.0" encoding="utf-8"?>
<root>
  <!-- 
    Microsoft ResX Schema 
    
    Version 2.0
    
    The primary goals of this format is to allow a simple XML format 
    that is mostly human readable. The generation and parsing of the 
    various data types are done through the TypeConverter classes 
    associated with the data types.
    
    Example:
    
    ... ado.net/XML headers & schema ...
    <resheader name="resmimetype">text/microsoft-resx</resheader>
    <resheader name="version">2.0</resheader>
    <resheader name="reader">System.Resources.ResXResourceReader, System.Windows.Forms, ...</resheader>
    <resheader name="writer">System.Resources.ResXResourceWriter, System.Windows.Forms, ...</resheader>
    <data name="Name1"><value>this is my long string</value><comment>this is a comment</comment></data>
    <data name="Color1" type="System.Drawing.Color, System.Drawing">Blue</data>
    <data name="Bitmap1" mimetype="application/x-microsoft.net.object.binary.base64">
        <value>[base64 mime encoded serialized .NET Framework object]</value>
    </data>
    <data name="Icon1" type="System.Drawing.Icon, System.Drawing" mimetype="application/x-microsoft.net.object.bytearray.base64">
        <value>[base64 mime encoded string representing a byte array form of the .NET Framework object]</value>
        <comment>This is a comment</comment>
    </data>
                
    There are any number of "resheader" rows that contain simple 
    name/value pairs.
    
    Each data row contains a name, and value. The row also contains a 
    type or mimetype. Type corresponds to a .NET class that support 
    text/value conversion through the TypeConverter architecture. 
    Classes that don't support this are serialized and stored with the 
    mimetype set.
    
    The mimetype is used for serialized objects, and tells the 
    ResXResourceReader how to depersist the object. This is currently not 
    extensible. For a given mimetype the value must be set accordingly:
    
    Note - application/x-microsoft.net.object.binary.base64 is the format 
    that the ResXResourceWriter will generate, however the reader can 
    read any of the formats listed below.
    
    mimetype: application/x-microsoft.net.object.binary.base64
    value   : The object must be serialized with 
            : System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
            : and then encoded with base64 encoding.
    
    mimetype: application/x-microsoft.net.object.soap.base64
    value   : The object must be serialized with 
            : System.Runtime.Serialization.Formatters.Soap.SoapFormatter
            : and then encoded with base64 encoding.

    mimetype: application/x-microsoft.net.object.bytearray.base64
    value   : The object must be serialized into a byte array 
            : using a System.ComponentModel.TypeConverter
            : and then encoded with base64 encoding.
    -->
  <xsd:schema id="root" xmlns="" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
    <xsd:import namespace="http://www.w3.org/XML/1998/namespace" />
    <xsd:element name="root" msdata:IsDataSet="true">
      <xsd:complexType>
        <xsd:choice maxOccurs="unbounded">
          <xsd:element name="metadata">
            <xsd:complexType>
              <xsd:sequence>
                <xsd:element name="value" type="xsd:string" minOccurs="0" />
              </xsd:sequence>
              <xsd:attribute name="name" use="required" type="xsd:string" />
              <xsd:attribute name="type" type="xsd:string" />
              <xsd:attribute name="mimetype" type="xsd:string" />
              <xsd:attribute ref="xml:space" />
            </xsd:complexType>
          </xsd:element>
          <xsd:element name="assembly">
            <xsd:complexType>
              <xsd:attribute name="alias" type="xsd:string" />
              <xsd:attribute name="name" type="xsd:string" />
            </xsd:complexType>
          </xsd:element>
          <xsd:element name="data">
            <xsd:complexType>
              <xsd:sequence>
                <xsd:element name="value" type="xsd:string" minOccurs="0" msdata:Ordinal="1" />
                <xsd:element name="comment" type="xsd:string" minOccurs="0" msdata:Ordinal="2" />
              </xsd:sequence>
              <xsd:attribute name="name" type="xsd:string" use="required" msdata:Ordinal="1" />
              <xsd:attribute name="type" type="xsd:string" msdata:Ordinal="3" />
              <xsd:attribute name="mimetype" type="xsd:string" msdata:Ordinal="4" />
              <xsd:attribute ref="xml:space" />
            </xsd:complexType>
          </xsd:element>
          <xsd:element name="resheader">
            <xsd:complexType>
              <xsd:sequence>
                <xsd:element name="value" type="xsd:string" minOccurs="0" msdata:Ordinal="1" />
              </xsd:sequence>
              <xsd:attribute name="name" type="xsd:string" use="required" />
            </xsd:complexType>
          </xsd:element>
        </xsd:choice>
      </xsd:complexType>
    </xsd:element>
  </xsd:schema>
  <resheader name="resmimetype">
    <value>text/microsoft-resx</value>
  </resheader>
  <resheader name="version">
    <value>2.0</value>
  </resheader>
  <resheader name="reader">
    <value>System.Resources.ResXResourceReader, System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
  </resheader>
  <resheader name="writer">
    <value>System.Resources.ResXResourceWriter, System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
  </resheader>
EOH
#'
}

sub xmlHeaderMoreUnfortunateStuffToHaveToHandle {
    my $self        = shift or croak 'no self' ;
return <<'EOF';
  <metadata name="checksumCondition1.Configuration" xml:space="preserve">
    <value>Press to configure</value>
  </metadata>
  <metadata name="expectedSchemaCondition1.Configuration" xml:space="preserve">
    <value>Press to configure</value>
  </metadata>
  <data name="expectedSchemaCondition1.Schema" mimetype="application/x-microsoft.net.object.binary.base64">
    <value>
        AAEAAAD/////AQAAAAAAAAAMAgAAAE5TeXN0ZW0uRGF0YSwgVmVyc2lvbj00LjAuMC4wLCBDdWx0dXJl
        PW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWI3N2E1YzU2MTkzNGUwODkFAQAAABNTeXN0ZW0uRGF0YS5E
        YXRhU2V0AwAAABdEYXRhU2V0LlJlbW90aW5nVmVyc2lvbglYbWxTY2hlbWELWG1sRGlmZkdyYW0DAQEO
        U3lzdGVtLlZlcnNpb24CAAAACQMAAAAGBAAAAL8SPD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0i
        dXRmLTE2Ij8+DQo8eHM6c2NoZW1hIGlkPSJOZXdEYXRhU2V0IiB4bWxucz0iIiB4bWxuczp4cz0iaHR0
        cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEiIHhtbG5zOm1zZGF0YT0idXJuOnNjaGVtYXMtbWlj
        cm9zb2Z0LWNvbTp4bWwtbXNkYXRhIj4NCiAgPHhzOmVsZW1lbnQgbmFtZT0iTmV3RGF0YVNldCIgbXNk
        YXRhOklzRGF0YVNldD0idHJ1ZSIgbXNkYXRhOlVzZUN1cnJlbnRMb2NhbGU9InRydWUiPg0KICAgIDx4
        czpjb21wbGV4VHlwZT4NCiAgICAgIDx4czpjaG9pY2UgbWluT2NjdXJzPSIwIiBtYXhPY2N1cnM9InVu
        Ym91bmRlZCI+DQogICAgICAgIDx4czplbGVtZW50IG5hbWU9IlRhYmxlIj4NCiAgICAgICAgICA8eHM6
        Y29tcGxleFR5cGU+DQogICAgICAgICAgICA8eHM6c2VxdWVuY2U+DQogICAgICAgICAgICAgIDx4czpl
        bGVtZW50IG5hbWU9IkNvbHVtbjEiIHR5cGU9InhzOmludCIgbXNkYXRhOnRhcmdldE5hbWVzcGFjZT0i
        IiBtaW5PY2N1cnM9IjAiIC8+DQogICAgICAgICAgICA8L3hzOnNlcXVlbmNlPg0KICAgICAgICAgIDwv
        eHM6Y29tcGxleFR5cGU+DQogICAgICAgIDwveHM6ZWxlbWVudD4NCiAgICAgICAgPHhzOmVsZW1lbnQg
        bmFtZT0iVGFibGUxIj4NCiAgICAgICAgICA8eHM6Y29tcGxleFR5cGU+DQogICAgICAgICAgICA8eHM6
        c2VxdWVuY2U+DQogICAgICAgICAgICAgIDx4czplbGVtZW50IG5hbWU9IlBlcnNvbklkIiB0eXBlPSJ4
        czppbnQiIG1zZGF0YTp0YXJnZXROYW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAg
        ICAgICA8eHM6ZWxlbWVudCBuYW1lPSJUaXRsZUlkIiB0eXBlPSJ4czppbnQiIG1zZGF0YTp0YXJnZXRO
        YW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAgICAgICA8eHM6ZWxlbWVudCBuYW1l
        PSJOYW1lU3VmZml4SWQiIHR5cGU9InhzOmludCIgbXNkYXRhOnRhcmdldE5hbWVzcGFjZT0iIiBtaW5P
        Y2N1cnM9IjAiIC8+DQogICAgICAgICAgICAgIDx4czplbGVtZW50IG5hbWU9IlN1cm5hbWUiIHR5cGU9
        InhzOnN0cmluZyIgbXNkYXRhOnRhcmdldE5hbWVzcGFjZT0iIiBtaW5PY2N1cnM9IjAiIC8+DQogICAg
        ICAgICAgICAgIDx4czplbGVtZW50IG5hbWU9IkZvcmVuYW1lIiB0eXBlPSJ4czpzdHJpbmciIG1zZGF0
        YTp0YXJnZXROYW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAgICAgICA8eHM6ZWxl
        bWVudCBuYW1lPSJPdGhlcm5hbWUiIHR5cGU9InhzOnN0cmluZyIgbXNkYXRhOnRhcmdldE5hbWVzcGFj
        ZT0iIiBtaW5PY2N1cnM9IjAiIC8+DQogICAgICAgICAgICAgIDx4czplbGVtZW50IG5hbWU9IlNleCIg
        dHlwZT0ieHM6c3RyaW5nIiBtc2RhdGE6dGFyZ2V0TmFtZXNwYWNlPSIiIG1pbk9jY3Vycz0iMCIgLz4N
        CiAgICAgICAgICAgICAgPHhzOmVsZW1lbnQgbmFtZT0iRGVsZXRlZCIgdHlwZT0ieHM6Ym9vbGVhbiIg
        bXNkYXRhOnRhcmdldE5hbWVzcGFjZT0iIiBtaW5PY2N1cnM9IjAiIC8+DQogICAgICAgICAgICAgIDx4
        czplbGVtZW50IG5hbWU9IkNMb2FkSWQiIHR5cGU9InhzOmludCIgbXNkYXRhOnRhcmdldE5hbWVzcGFj
        ZT0iIiBtaW5PY2N1cnM9IjAiIC8+DQogICAgICAgICAgICAgIDx4czplbGVtZW50IG5hbWU9IkNTcmNJ
        ZCIgdHlwZT0ieHM6aW50IiBtc2RhdGE6dGFyZ2V0TmFtZXNwYWNlPSIiIG1pbk9jY3Vycz0iMCIgLz4N
        CiAgICAgICAgICAgICAgPHhzOmVsZW1lbnQgbmFtZT0iVUxvYWRJZCIgdHlwZT0ieHM6aW50IiBtc2Rh
        dGE6dGFyZ2V0TmFtZXNwYWNlPSIiIG1pbk9jY3Vycz0iMCIgLz4NCiAgICAgICAgICAgICAgPHhzOmVs
        ZW1lbnQgbmFtZT0iVVNyY0lkIiB0eXBlPSJ4czppbnQiIG1zZGF0YTp0YXJnZXROYW1lc3BhY2U9IiIg
        bWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAgICAgICA8eHM6ZWxlbWVudCBuYW1lPSJVUHJvY0lkIiB0
        eXBlPSJ4czppbnQiIG1zZGF0YTp0YXJnZXROYW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAg
        ICAgICAgICAgICA8eHM6ZWxlbWVudCBuYW1lPSJEb0JpcnRoIiB0eXBlPSJ4czpkYXRlVGltZSIgbXNk
        YXRhOnRhcmdldE5hbWVzcGFjZT0iIiBtaW5PY2N1cnM9IjAiIC8+DQogICAgICAgICAgICAgIDx4czpl
        bGVtZW50IG5hbWU9IkluZGl2aWR1YWxJZCIgdHlwZT0ieHM6aW50IiBtc2RhdGE6dGFyZ2V0TmFtZXNw
        YWNlPSIiIG1pbk9jY3Vycz0iMCIgLz4NCiAgICAgICAgICAgIDwveHM6c2VxdWVuY2U+DQogICAgICAg
        ICAgPC94czpjb21wbGV4VHlwZT4NCiAgICAgICAgPC94czplbGVtZW50Pg0KICAgICAgPC94czpjaG9p
        Y2U+DQogICAgPC94czpjb21wbGV4VHlwZT4NCiAgPC94czplbGVtZW50Pg0KPC94czpzY2hlbWE+BgUA
        AACAATxkaWZmZ3I6ZGlmZmdyYW0geG1sbnM6bXNkYXRhPSJ1cm46c2NoZW1hcy1taWNyb3NvZnQtY29t
        OnhtbC1tc2RhdGEiIHhtbG5zOmRpZmZncj0idXJuOnNjaGVtYXMtbWljcm9zb2Z0LWNvbTp4bWwtZGlm
        ZmdyYW0tdjEiIC8+BAMAAAAOU3lzdGVtLlZlcnNpb24EAAAABl9NYWpvcgZfTWlub3IGX0J1aWxkCV9S
        ZXZpc2lvbgAAAAAICAgIAgAAAAAAAAD//////////ws=
</value>
  </data>
EOF
}

sub xmlFooter {
    my $self        = shift or croak 'no self' ;
return <<'EOF';
  <metadata name="$this.Localizable" type="System.Boolean, mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089">
    <value>True</value>
  </metadata>
</root>
EOF
}


1 ;


__DATA__
