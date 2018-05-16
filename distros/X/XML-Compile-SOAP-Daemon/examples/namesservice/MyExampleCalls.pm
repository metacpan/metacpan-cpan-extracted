# Copyrights 2007-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

# This pm file demonstrates how a client-side and server-side definition
# of a message can be created, in case there is no WSDL for the SOAP
# interface.  This same module is used in both client.pl and server.pl.

package MyExampleCalls;
use vars '$VERSION';
$VERSION = '3.14';

use base qw/Exporter/;

use XML::Compile::Util  qw/pack_type SCHEMA2001/;

our @EXPORT = qw/
    @my_additional_schemas
    @get_name_count_input @get_name_count_output
  /;

# You may have some types you need to load as well.  You can use filenames
# or strings, or... anything XML::Compile::dataToXML() accepts.

my $myns     = 'http://my-test-ns';
my $schemans = SCHEMA2001;

our @my_additional_schemas = ( <<__XML );
<schema
  xmlns="$schemans"
  targetNamespace="$myns" xmlns:me="$myns"
  elementFormDefault="qualified"
  attributeFormDefault="unqualified">

<!-- this is the first (and only) body element for the message which
     is send from client to the server
  -->

<element name="getNameCount">
  <complexType>
    <sequence>
      <element name="country" type="string"/>
    </sequence>
  </complexType>
</element>

<!-- the only body element as answer
  -->

<element name="getNameCountResponse">
  <complexType>
    <sequence>
      <element name="count" type="int"/>
    </sequence>
  </complexType>
</element>

</schema>
__XML

# WSDL term 'input' means: input for the server; the request which the
# client will sends to the server.
# In this example, the lines which define the message --to be specified
# with method XML::Compile::SOAP::compileMessage()-- are listed.

our @get_name_count_input =
 ( body => [ request =>  pack_type($myns, 'getNameCount') ]
 );

# WSDL term 'output': send by the server, as response to the client's
# request.

our @get_name_count_output =
 ( body => [ answer => pack_type($myns, 'getNameCountResponse') ]
 );

1;
