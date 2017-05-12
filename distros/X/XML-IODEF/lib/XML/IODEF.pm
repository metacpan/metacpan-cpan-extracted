package XML::IODEF;

# syntax cerbere
use 5.006;
use strict;
use warnings;

# various includes
use Carp;
use XML::DOM;
use DateTime;
use XML::Simple;

# export, version, inheritance
require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(xml_encode
		 xml_decode
		 byte_to_string
		 extend_iodef	
		 extend_dtd
		 set_doctype_name
		 set_doctype_sysid
		 set_doctype_pubid
		 );

our $VERSION = '0.11';

our $MAX_ITER = 20;



##----------------------------------------------------------------------------------------
##
## IODEF - An XML wrapper for building/parsing IODEF messages
##
## Erwan Lemonnier - Proact Defcom - 2002/05
## Adapted to IODEF by John Green - JANET-CERT - 2003/07
## Updated to RFC 5070 Release 2007 -- Wes Young 2010/01
##
## DESC:
##
##    IODEF.pm is an interface for simply creating and parsing IODEF messages.
##    It is compliant with IODEF v1.0, and hence provides calls for building Incident,
##    ToolIncident, CorrelationIncident, OverflowIncident and Heartbeat IODEF messages.
##
##    This interface has been designed for simplifying the task of translating a
##    key-value based format to its iodef representation. A typical session involves
##    the creation of a new IODEF message, the initialisation of some of it's fields
##    and its conversion into an IODEF string, as illustrated below:
##
##        use XML::IODEF;
##
##        my $iodef = new XML::IODEF();
##        $iodef->create_time();
##        $iodef->add("IncidentAdditionalData", "myvalue", "mymeaning"); 
##        $iodef->add("IncidentAdditionalData", byte_to_string($bytes), "binary-data", "byte");
##        print $iodef->out();
##
##    An interface to load and parse an IODEF message is also provided (with the
##    'to_hash' function), but is quite limited.
##
##    This module is based on XML::DOM and contains a simplified version of the latest
##    IODEF DTD. It is hence DTD aware and perform some validity checks on the IODEF
##    message treated, in an attempt at easying the process of producing valid IODEF
##    messages.
##
##    This simplified internal DTD representation can easily be upgraded or extended to
##    support new XML node. For information on how to extend IODEF with IODEF.pm, read
##    the documentation in the source code.
## 
##
## REM: to extract the api documentation, do 'cat IODEF.pm | grep "##" | sed -e "s/##//"'
##
##
## BSD LICENSE:
##
##         All rights reserved.
##
##         Redistribution and use in source and binary forms, with or without modification, are permitted
##         provided that the following conditions are met:
##
##              Redistributions of source code must retain the above copyright notice, this list 
##              of conditions and the following disclaimer. 
##              Redistributions in binary form must reproduce the above copyright notice, this list of
##              conditions and the following disclaimer in the documentation and/or other materials
##              provided with the distribution. 
##              Neither the name of the <ORGANIZATION> nor the names of its contributors may be used
##              to endorse or promote products derived from this software without specific prior written
##              permission. 
##
##         THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
##         AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
##         IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
##         ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
##         LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
##         CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
##         SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
##         INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
##         CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
##         ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
##         POSSIBILITY OF SUCH DAMAGE.
##
##----------------------------------------------------------------------------------------
##
## LIST OF FUNCTIONS
##
##    new             # create new IODEF message
##    in              # load new IODEF message from string/file
##    out             # write IODEF message to string/file
##
##    to_hash         # convert IODEF message to hash for easy parsing
##    add             # add a field to IODEF message
##    get_type        # return type of IODEF message
##
##    create_time     # initialize the CreateTime field with the current time
##
## EXPORTS:
##
##    xml_encode      # encode data (not binary) into an IODEF compliant string
##    xml_decode      # and the other way round
##    byte_to_string  # encode binary data into an IODEF compliant string
##
##
##




#
# IODEF DTD REPRESENTATION
# ------------------------
#
# The IODEF DTD, as all DTDs, can be represented as a class hierarchy in which
# each class corresponds to one node level. There can be 2 kind of relations between
# these node classes: inheritance (ex: a ToolIncident is an Incident) and composition
# (Incident contains Analyzer, Source, Target...).
# 
# Below is a hash structure, called 'IODEF_DTD', which defines the whole IODEF DTD
# as in version xxx. Each key is the name of the root tag of an IODEF node, and its
# value is a structure representing the attributes, tags and subnodes allowed for
# this node, as well as the node's subclasses if there are some. If on attribute can
# take only a limited set of values, this is also specified. One class element (tag,
# attribute or node) may appear more than once, in which case it is specified.
#
# This IODEF DTD is then parsed by the 'load_xml_dtd' function when the IODEF.pm
# module is loaded, which in turn builds two internal and more convenient 
# representations: $EXPAND_PATH & $CHECK_VALUE. These 2 hashes are used by the add()
# call, and faster to use than the DTD class construction.
#
# The main advantage of prefering a DTD representation of IODEF is its flexibility:
# if the IODEF rfc happens to change, the DTD hash is the only part of this module
# which will need an upgrade. Beside, it gets easy to extend IODEF by adding to the
# DTD some home-defined root class, and extend IODEF.pm. The extension module only
# needs to contain a DTD hash extending the one of IODEF, and call 'extend_iodef'.
# All other functions ('in', 'out', 'add', 'to_hash'...) are then inherited from IODEF.
#
# This code is actually build in a very generic way and could be used with whatever 
# other XML format.
#
# DTD hash:
# ---------
#
# A DTD is represented as a hash where each key is the name of a node, and each value
# a hash encoding the corresponding DTD definition of this node.
# This hash describes the attributes, children and content type of this node,
# and can be deduced directly from the corresponding ELEMENT and ATTRIBUTE definitions
# in the DTD. Yet, some subtilities from the DTD, such as complex combinations
# of allowed children order and occurence, can not be represented in this model.
# That's why this DTD representation only is a pseudo-DTD, and will not be able 
# to comply to some case of complex DTDs.
#
# A node has a name, which is its tag string. This name is the node's key in the DTD
# hash.
#
# A node may has children nodes. These children are listed in an anonymous array 
# associated to the CHILDREN key. Each element of this children array is a string 
# made of the name of the child node preceded by a one letter prefix representing
# the allowed occurencies of this child node. This prefix should be one of:
#
#   prefix    meaning
#   ------    -------
#
#   ?         0 or 1 occurences
#   +         1 or more 
#   *         0 or more
#   1         exactly one
#   #         unknown   (in practice, same as *)
#
# The order of the children names in the children array reflects the order of
# children nodes in the DTD. As a result, the XML::IODEF API allows only to
# create XML messages with one given order of children in each node. If the DTD
# allows other combinations, it can not be encoded in XML::IODEF, and you will
# have to choose one of the possible combinations when writting the pseudo-DTD.
# In some cases, this won't be possible. That's why this API can not yet be
# generalised to any generating any XML format. 
#
# A node can also have attributes, which are represented as keys of the ATTRIBUTES
# hash. The value associated with each key is an array of the values allowed for this
# attributes, or an empty array if there are no restrictions on the value.
#
# Finally, a node can have a content, declared under the CONTENT key. That key can
# accept 3 values: ANY, PCDATA, EMPTY. In practice, all are treated as PCDATA internaly.
#
# ex: DTD entity definition
#
# "EntityName" = {
#            ATTRIBUTES  => { "attribute1" => [ list of values ],
#                             "attribute2" => [],
#                             ...
#                           },
#            CHILDREN    => [ "<occurence_code>elem1", "<occurence_code>elem2"... ],
#            CONTENT     => ANY | PCDATA | EMPTY
#          }
#


#
# CONTENT:
# --------
#
# the official xml contents supported by this simplified DTD representation

use constant ANY    => "ANY";
use constant PCDATA => "PCDATA";
use constant EMPTY  => "EMPTY";



#
# IODEF_DTD:
# ----------
#
# A hash encoding all the xml entities defined in the IODEF DTD, as
# specified in the version $IODEF_VERSION of the IODEF draft.
#
# REM: this is a simplified DTD representation and does not reflect
# exactly the content of the IODEF DTD.
# In particular, this representation does not properly represent
# for each entity the allowed number and occurences of its children.

# version of the IODEF draft used for this DTD
my $IODEF_VERSION = "1.0";

my $IODEF_DTD = {

    # each children of an entity should have a 1 letter code prefixed
    # to its name, reflecting the occurences, as allowed by the DTD, and
    # according to the list below:
 
    "IODEF-Document" => {
		ATTRIBUTES  => { 
            "version"               => ["1.0"], 
            "lang"                  => [], 
            "formatid"              => [],
            "xmlns:iodef"           => [ "urn:ietf:params:xml:ns:iodef-1.0" ],
            "xmlns:xsi"             => [ "http://www.w3.org/2001/XMLSchema-instance" ],
            "xsi:schemaLocation"    => [ "urn:ietf:params:xmls:schema:iodef-1.0" ]
        },
		CHILDREN    => [ "+Incident" ],
    },

    "Incident" => {
		ATTRIBUTES  => { 
			"purpose"		=> [ "traceback", "mitigation", "reporting", "other", "ext-value" ],
			"ext-purpose"	=> [],
			"lang"			=> [],
			"restriction"	=> [ "public", "need-to-know", "private", "default" ]
		},
		CHILDREN    => [ "1IncidentID", "?AlternativeID", "?RelatedActivity", "?DetectTime",
						 "?StartTime", "?EndTime", "1ReportTime", "*Description", "+Assessment", 
						 "*Method", "+Contact", "*EventData", "?History", "*AdditionalData" ]
	},
	
	"IncidentID"	=> {
		ATTRIBUTES	=> {
			"name"			=> [], 
			"instance"		=> [],
			"restriction"	=> [ "public", "need-to-know", "private", "default" ]
		},
		CONTENT		=> PCDATA
	},
	
    "AlternativeID"	=> {
        ATTRIBUTES  => {
            "restriction"	=> [ "public", "need-to-know", "private", "default" ]   
        },
        CHILDREN    => ["+IncidentID"]
    },
    
    "RelatedActivity" => {
        ATTRIBUTES    => { "restriction" => [ "public", "need-to-know", "private", "default" ] },
        CHILDREN      => [ "*IncidentID", "*URL" ],
    },
    
    "AdditionalData" => {
        ATTRIBUTES  => { 
            "dtype" => ["boolean", "byte", "character", "date-time", "integer", "portlist",
                                     "real", "string", "file", "frame", "packet", "ipv4-packet", "ipv6-packet",
                                     "path", "url", "csv", "winreg", "xml", "ext-value"],
            "ext-dtype"    => [],
            "meaning"      => [],
            "formatid"     => [],
            "restriction" => [ "public", "need-to-know", "private", "default" ],
        },
        CONTENT     => ANY,
    }, 
    
    "Contact" => { 
        ATTRIBUTES  => { 
			"role"         => [ "creator", "admin", "tech", "irt", "cc", "ext-value" ],
            "ext-role"     => [],
            "type"         => [ "person", "organization", "ext-value" ],
            "ext-type"     => [],
            "restriction"  => [ "public", "need-to-know", "private", "default" ]
        },
        CHILDREN    => [ "?ContactName", "*Description", "*RegistryHandle","?PostalAddress","*Email",
                         "*Telephone", "?Fax", "?Timezone", "*Contact", "*AdditionalData" ],
    },
    
    "RegistryHandle" => {
        ATTRIBUTES   => { 
            "registry"      => [ "internic", "apnic", "arin", "lacnic", "ripe", "afrinic", "local", "ext-value" ],
            "ext-registry"  => [],
        },
        CONTENT      => PCDATA,
    },
    
    "PostalAddress" => {
        ATTRIBUTES  => {
            "meaning"   => [],
            "lang"      => [],
        },
        CONTENT => PCDATA
    },
    
    "Email" => {
        ATTRIBIUTES => {
            "meaning"   => [],
        },
        CONTENT     => PCDATA
    },
    
    "Telephone" => {
        ATTRIBUTES  => {
            "meaning"   => [],
        },
        CONTENT => PCDATA
    },
    
    "Fax"   => {
        ATTRIBUTES  => {
            "meaning"   => []
        },
        CONTENT     => PCDATA
    },
    
    "StartTime" => {
        CONTENT => PCDATA
    },
    
    "EndTime" => {
        CONTENT => PCDATA
    },
    
    "DetectTime" => {
        CONTENT => PCDATA
    },
    
    "ReportTime" => {
        CONTENT => PCDATA
    },
    
    "DateTime" => {
        CONTENT => PCDATA
    },
    
    "Method"    => {
        ATTRIBUTES => {
            "restriction"  => [ "public", "need-to-know", "private", "default" ]
        },
        CHILDREN    => ["*Reference", "*Description", "*AdditionalData"],
    },
    
    "Reference" => {
        CHILDREN    => ["1ReferenceName", "*URL", "*Description"],
    },
    
    "Assessment"    => {
        ATTRIBUTES  => {
            "occurence"     => ["actual", "potential"],
            "restriction"   => [ "public", "need-to-know", "private", "default" ]
        },
        CHILDREN    => [ "*Impact", "*TimeImpact", "*MonetaryImpact", "*Counter", "?Confidence",
                         "*AdditionalData"]
    },
    
    "Impact"    => {
        ATTRIBUTES  => {
            "lang"          => [],
            "severity"      => [ "low", "medium", "high" ],
            "completion"    => [ "failed", "succeeded" ],
            "type"          => [ "admin", "dos", "file", "info-leak", "misconfiguration",
                                 "policy", "recon", "social-engineering", "user", "unknown",
                                 "ext-value"],
            "ext-type"      => [],
        },
        CONTENT => PCDATA
    },
    
    "TimeImpact"    => {
        ATTRIBUTES  => {
            "severity"      => [ "low", "medium", "high" ],
            "metric"        => [ "labor", "elapsed", "downtime", "ext-value" ],
            "ext-metric"    => [],
            "duration"      => [ "second", "minute", "hour", "day", "month", "quarter", "year", "ext-value" ],
            "ext-duration"  => []
        },
        CONTENT => PCDATA
    },
    
    "MonetaryImpact"    => {
        ATTRIBUTES  => {
            "severity"  => [ "low", "medium", "high" ],
            "currency"  => []
        },
        CONTENT => PCDATA
    },
	
    "Confidence"    => {
        ATTRIBUTES  => {
            "rating"    => [ "low", "medium", "high", "numeric" ],
        },
        CONTENT => PCDATA,
    },
    
    "History"   => {
        ATTRIBUTES  => {
            "restriction"  => [ "public", "need-to-know", "private", "default" ]
        },
        CHILDREN    => [ "+HistoryItem" ],
    },
    
    "HistoryItem"   => {
        ATTRIBUTES  => {
            "restriction"   => [ "public", "need-to-know", "private", "default" ],
            "action"        => [ "nothing", "contact-source-site", "contact-target-site", "contact-sender", "investigate",
                                 "block-host", "block-network", "block-port", "rate-limit-host", "rate-limit-network",
                                 "rate-limit-port", "remediate-other", "status-triage", "status-new-info", "other",
                                 "ext-value" ],
            "ext-action"    => []
        },
        CHILDREN    => [ "1DateTime", "?IncidentID", "?Contact", "*Description", "*AdditionalData" ],
    },
    
    "EventData" => {
        ATTRIBUTES  => {
            "restriction"   => [ "public", "need-to-know", "private", "default" ],
        },
        CHILDREN    => [ "*Description", "?DetectTime", "?StartTime", "?EndTime", "*Contact",
                         "?Assessment", "*Method", "*Flow", "*Expectation", "?Record",
                         "*EventData", "*AdditionalData"]
    },
    
    "Expectation"   => {
        ATTRIBUTES  => {
            "restriction"   => [ "public", "need-to-know", "private", "default" ],
            "severity"      => [ "low", "medium", "high" ],
            "action"        => [ "nothing", "contact-source-site", "contact-target-site", "contact-sender", "investigate",
                                 "block-host", "block-network", "block-port", "rate-limit-host", "rate-limit-network",
                                 "rate-limit-port", "remediate-other", "status-triage", "status-new-info", "other",
                                 "ext-value" ],
            "ext-action"    => []
        },
        CHILDREN    => [ "*Description", "?StartTime", "?EndTime", "?Contact" ]
    },
    
    "Flow"  => {
        CHILDREN    => [ "+System" ],
    },
    
    "System"    => {
        ATTRIBUTES  => {
            "restriction"   => [ "public", "need-to-know", "private", "default" ],
            "category"      => [ "source", "target", "intermediate", "sensor" , "infrastructure",
                                 "ext-value" ],
            "ext-category"  => [],
            "interface"     => [],
            "spoofed"       => [ "unknown", "yes", "no" ],
        },
        CHILDREN    => [ "1Node", "*Service", "*OperatingSystem", "*Description", "*AdditionalData" ]
    },
    
    "Node"  => {
        CHILDREN    => [ "*NodeName", "*Address", "?Location", "?DateTime", "*NodeRole",
                         "*Counter"]
    },
    
    "Counter"   => {
        ATTRIBUTES  => {
            "type"          => [ "byte", "packet", "flow", "session", "alert",
                                 "message", "event", "host", "site", "organization",
                                 "ext-value" ],
            "ext-type"      => [],
            "meaning"       => [],
            "duration"      => [ "second", "minute", "hour", "day", "month", "quarter", "year", "ext-value" ],
            "ext-duration"  => [],
        },
        CONTENT     => PCDATA
    },
    
    "Address"   => {
        ATTRIBUTES  => {
            "category"  => [ "asn", "atm", "e-mail", "ipv4-addr", "ipv4-net",
                             "ipv4-net-mask", "ipv6-addr", "ipv6-net", "ipv6-net-mask", "mac",
                             "ext-value" ],
            "ext-category"  => [],
            "vlan-name"     => [],
            "vlan-num"      => [],
        },
        CONTENT => PCDATA
    },
    
    "NodeRole"  => {
        ATTRIBUTES  => {
            "category"      => [ "client", "server-internal", "server-public", "www", "mail",
                                 "messaging", "streaming", "voice", "file", "ftp",
                                 "p2p", "name", "directory", "credential", "print",
                                 "application", "database", "infra", "log", "ext-value"],
            "ext-category"  => [],
            "lang"          => [],
        }
    },
    
    "Service"   => {
        ATTRIBUTES  => {
            "ip_protocol"   => [],
        },
        CHILDREN    => [ "?Port", "?Portlist", "?ProtoCode", "?ProtoType", "?ProtoFlags",
                         "?Application" ]
    },
    
    "Application"   => {
        ATTRIBUTES  => {
            "swid"      => [],
            "configid"  => [],
            "vendor"    => [],
            "family"    => [],
            "name"      => [],
            "version"   => [],
            "patch"     => [],
        },
        CHILDREN    => [ "?URL" ]
    },
    
    "OperatingSystem"   => {
        ATTRIBUTES  => {
            "swid"      => [],
            "configid"  => [],
            "vendor"    => [],
            "family"    => [],
            "name"      => [],
            "version"   => [],
            "patch"     => [],
        },
        CHILDREN    => [ "?URL" ]
    },

    "Record"    => {
        ATTRIBUTES  => {
            "restriction"   => [ "public", "need-to-know", "private", "default" ],
        },
        CHILDREN    => [ "+RecordData" ]
    },
    
    "RecordData"    => {
        ATTRIBUTES  => {
            "restriction"   => [ "public", "need-to-know", "private", "default" ],
        },
        CHILDREN    => [ "?DateTime", "*Description", "?Application", "*RecordPattern", "+RecordItem",
                         "*AdditionalData" ]
    },
    
    "RecordPattern" => {
        ATTRIBUTES  => {
            "type"              => [ "regex", "binary", "xpath", "ext-value" ],
            "ext-type"          => [],
            "offset"            => [],
            "offsetunit"        => [ "line", "binary", "ext-value" ],
            "ext-offsetunit"    => [],
            "instance"          => [],
        },
        CONTENT => PCDATA,
    },
    
    "RecordItem"    => {
        ATTRIBUTES  => { "dtype" => ["boolean", "byte", "character", "date-time", "integer", "portlist",
            "real", "string", "file", "frame", "packet", "ipv4-packet", "ipv6-packet",
            "path", "url", "csv", "winreg", "xml", "ext-value"],
            "ext-dtype"    => [],
            "meaning"      => [],
            "formatid"     => [],
            "restriction" => [ "public", "need-to-know", "private", "default" ],
        },
        CONTENT     => ANY,
    },
 
    #
    # Simple elements with no sub-elements and no attributes
    #
    "Description"   => { CONTENT => PCDATA },
    "URL"           => { CONTENT => PCDATA },
    "ContactName"   => { CONTENT => PCDATA },
    "Timezone"      => { CONTENT => PCDATA },
    "ReferenceName" => { CONTENT => PCDATA },
    "NodeName"      => { CONTENT => PCDATA },
    "Location"      => { CONTENT => PCDATA },
    "Port"          => { CONTENT => PCDATA },
    "Portlist"      => { CONTENT => PCDATA },
    "ProtoCode"     => { CONTENT => PCDATA },
    "ProtoType"     => { CONTENT => PCDATA },
    "ProtoFlags"    => { CONTENT => PCDATA },

};




##--------------------------------------------------------------------------------
##
##
## CLASS METHODS:
## --------------
##
##
##--------------------------------------------------------------------------------




##================================================================================
##
## XML PSEUDO DTD LOADER
##
##================================================================================
##
##  Below is the generic code for loading a pseudo DTD representation of an XML
##  DTD into structures optimised for internal usage.
##



# $EXPAND_PATH is a hash table linking an iodef tag path to the corresponding list
# of arguments needed to add a value at this path with the add() call.
# each key is a tagpath to a given IODEF field, as given to the 'add()' call.
# each corresponding value is an array containing the list of tags in the
# tagpath, preceded by 2 values. The first one is 'A' if the pointed field is
# an attribute, 'C' if it is a content, 'N' if it is just a node. Notice that
# a C path is a N path.
# ex:
#    'IncidentEventDatarestriction'     => [ A, "Incident", "EventData", "restriction"],
#    'Incidentpurpose'                  => [ A, "Incident", "purpose"],
#    'IncidentDescription'              => [ C, "Incident", "Description"],
#    'IncidentEventDataStartTime'       => [ C, "Incident", "EventData", "StartTime"],
#    'IncidentContact                   => [ N, "Incident", "Contact"],

my $EXPAND_PATH = {};


# hash of the tagpaths for which the values can only take a limited set of values
# which can be checked with check_allowed. each key is a tagpath, each value is
# an array of the corresponding allowed values.
#
# ex: 
#    'Incidentpurpose' => [ 'reporting', 'mitigation'... ],
#

my $CHECK_VALUE = {};


# DEPRECATED
# a counter used by create_ident's unique id generator
#

my $ID_COUNT = 0;


#
# Internal variables describing the DTD in use 
# --------------------------------------------
#
# This variables are to be initiated by a serie
# of api calls, listed below.

my $DTD = undef;
my $ROOT = undef;


#
# xml declaration
#

my $XML_DECL_VER = "1.0";
my $XML_DECL_ENC = "UTF-8";


#
# IODEF DTD declaration
#

my $DOCTYPE_NAME  = "IODEF-Document";
my $DOCTYPE_SYSID = "IODEF-Document.dtd";
my $DOCTYPE_PUBID = "-//IETF//DTD RFC 5070 IODEF v1.0//EN";



##----------------------------------------------------------------------------------------
##
## set_doctype_name(<string>)
## set_doctype_sysid(<string>)
## set_doctype_pubid(<string>)
##

sub set_doctype_name  { $DOCTYPE_NAME = shift; }
sub set_doctype_sysid { $DOCTYPE_SYSID = shift; }
sub set_doctype_pubid { $DOCTYPE_PUBID = shift; }



##----------------------------------------------------------------------------------------
##
## extend_dtd($DTD_extension, "new_root_class")
##
## ARGS:
##   $DTD_extension    a DTD hash, as described in the source doc above.
##   "new_root_class"  the name of a new root class
##
## RETURN:
##  This function can be used to extend IODEF by adding a new
##  root class definition to the original IODEF DTD.
##  $DTD_extension is a DTD hash, as defined above, providing definitions
##  for all the new IODEF classes introduced by the extension, including
##  the one for the new root class.
##  "new_root_class" is the name of the root node of the IODEF extension.
##  From now on, the usual IODEF calls ('in', 'add', 'to_hash'...) can be
##  used to create/parse extended messages as well. 
##
##  To extend IODEF, use extend_dtd(<hash_containing_new_iodef_node+replacement_nodes>, "IODEF-Message")
##  To load a new DTD, extend_dtd(<new hash>, "new root") + call set_doctype_*
##

sub extend_dtd {
    my($dtd, $name) = @_;

    $name = "IODEF-Document" if (!defined($name));
    
    foreach my $k (keys(%{$dtd})) {
	$IODEF_DTD->{$k} = $dtd->{$k};
    }

    load_xml_dtd($IODEF_DTD, $name);
}



##----------------------------------------------------------------------------------------
##
## load_xml_dtd(<DTD>, <ROOT_CLASS>)
##
## ARGS:
##   <DTD>         a DTD hash
##   <ROOT_CLASS>  the name (string) of the DTD's root class
##
## RETURN:
##  This is the DTD parser used to load the IODEF DTD in the DTD
##  engine at startup.
##  This function parses the DTD entity list as defined
##  through the <DTD> hash and builds the xml class tree of
##  the root node <ROOT_CLASS>. 
##
## EX:
##    # load the IODEF DTD at startup
##    load_xml_dtd($IODEF_DTD, "IODEF-Message");
##

sub load_xml_dtd {
    my($dtd, $root) = @_;

    defined($dtd)
	|| croak "XML::IODEF - load_xml_dtd: received a null ref in place of DTD hash.";
    defined($root)
	|| croak "XML::IODEF - load_xml_dtd: received a null ref in place of DTD root name.";
    exists($dtd->{$root})
	|| croak "XML::IODEF - load_xml_dtd: the root entity \'$root\' is not defined in the DTD hash.";

    my $err = check_xml_dtd($dtd, $root, 0);
    croak "XML::IODEF - load_xml_dtd: $err errors in the pseudo DTD. dying."
	if ($err > 0);

    # everything fine, accept DTD
    $DTD = $dtd;
    $ROOT = $root;
    
    fill_internal_hashes($DTD, "1".$ROOT,0);

    return 0;
}



#----------------------------------------------------------------------------------------
# 
# fill_internal_hashes(<DTD>, <ENTITY_NAME> [, @path])
#
# build the EXPAND_PATH and CHECK_VALUE hashes.
# it works recursively, and @path is the path of tags
# of where we currently are in the xml tree.
#

sub fill_internal_hashes {
    my($dtd, $name, $depth, @path) = @_;
    my($node, $k, $v, $type, $att, $kid, $vals);

    $node = $dtd->{substr($name,1)};
    $k = join '', map({substr $_, 1} @path, $name);

    # add node too EXPAND_PATH, as a node or content
    if (exists($node->{CONTENT})) {
	$EXPAND_PATH->{$k} = ['C', @path, $name];
    } else {
	$EXPAND_PATH->{$k} = ['N', @path, $name]; 
    }

    # does it have attributes? if so, add them.
    if (exists($node->{ATTRIBUTES})) {
	foreach $att (keys %{$node->{ATTRIBUTES}}) {
	    $EXPAND_PATH->{$k.$att} = ['A', @path, $name, $att];
	    
	    # fill CHECK_VALUE hash
	    $vals = $node->{ATTRIBUTES}->{$att};
	    $CHECK_VALUE->{$k.$att} = $vals
		if ((scalar @{$vals}) > 0);
	}
    }

    # does it have children elements? if so, add them.
    if (exists($node->{CHILDREN}) && ( $depth < $MAX_ITER) ) {
	foreach $kid (@{$node->{CHILDREN}}) {
	    fill_internal_hashes($dtd, $kid, $depth+1, @path, $name);
	}
    }

    return 0;
}



#----------------------------------------------------------------------------------------
#
# check_xml_dtd(<DTD>, <ENTITY_NAME>)
#
# internal function, called by load_xml_dtd to validate the pseudo DTD's
# syntax. recursive function. log errors to stdout.
# 
# return 0 if no error found, a positive number (error count) if errors found.
# If error found, the module should croak.
#

sub check_xml_dtd {
    my($dtd, $name, $depth) = @_;
    my($ent, $code, $child);
    my $ret = 0;

    # check if entity is defined in pseudo-dtd
    if (!exists($dtd->{$name})) {
	print "XML::IODEF - check_xml_dtd: entity \'$name\' is not defined in the pseudo DTD.\n";
	return 1;
    }

    $ent = $dtd->{$name};

    # check entity content code
    if (exists($ent->{CONTENT})) {
	$code = $ent->{CONTENT};
	if ($code ne PCDATA && $code ne ANY && $code ne EMPTY) {
	    print "XML::IODEF - check_xml_dtd: entity \'$name\' does not have a valid content.\n";
	    $ret++;
	}
    }

    # check each child of this entity
    if (exists($ent->{CHILDREN}) && ($depth < $MAX_ITER)) {
	$code = $ent->{CHILDREN};
	foreach $child (@{$code}) {
	    
	    # check that children starts with occurence code
	    if (index("?*+1#", substr($child,0,1)) == -1) {
		print "XML::IODEF - check_xml_dtd: children \'$child\' of entity \'$name\' does not have a proper occurence code.\n";
		$ret++;
	    } else {
		# check children's validity
		$ret += check_xml_dtd($dtd, substr($child,1), $depth+1);
	    }
	}
    }
    
    return $ret;
}



##--------------------------------------------------------------------------------
##
## MODULE LOAD TIME INITIALISATION
##
##--------------------------------------------------------------------------------

# DTD engine initialization:
#    load the IODEF root classes: Incident, and build the intermediary 
#    structures representing the DTD (EXPAND_PATH & CHECK_VALUE) used by API calls
#    such as add(). 
load_xml_dtd($IODEF_DTD, "IODEF-Document");



# return true to package loader
1;





##--------------------------------------------------------------------------------
##
##
## OBJECT METHODS:
## ---------------
##
##
##--------------------------------------------------------------------------------



##----------------------------------------------------------------------------------------
##
## new IODEF()
##
## RETURN
##   a new empty IODEF message, with initiated doctype and xml declaration
##   as well as root element and IODEF version tag.
##
## DESC
##   create a new empty iodef message
##
## EXAMPLES:
##   $iodef = new XML::IODEF();
##

sub new {
    my($iodef, $doc, $x);

    $iodef = {};
    bless($iodef, "XML::IODEF");

    $doc = new XML::DOM::Document();

    #$x = $doc->createDocumentType($DOCTYPE_NAME, $DOCTYPE_SYSID, $DOCTYPE_PUBID); 
    #$doc->setDoctype($x);
    
    $x = $doc->createXMLDecl($XML_DECL_VER, $XML_DECL_ENC);
    $doc->setXMLDecl($x);
    
    $iodef->{"DOM"} = $doc;

    $iodef->add("version", $IODEF_VERSION);
#    $iodef->add("xmlns:iodef", "urn:ietf:params:xml:ns:iodef-1.0");
    $iodef->add("xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance");
    $iodef->add("xsi:schemaLocation","urn:ietf:params:xmls:schema:iodef-1.0");

    return $iodef;
}



##----------------------------------------------------------------------------------------
##
## in(<iodef>, <string>)
##
## ARGS:
##   <iodef>   iodef object
##   <string>  can be either a path to an IODEF file to load, or an IODEF string.
##             if it is an empty string, a new empty IODEF message is created.
## RETURN:
##   a hash to the loaded IODEF message
##
## DESC:
##   loads an iodef message into an IODEF container (a hash with XML::Simple syntax)
##   the input can either be a string, a file or an empty string. if the parsed IODEF
##   message does not include an XML or DOCTYPE declaration, it will be added, assuming
##   IODEF v1.0 as the default.
##
## EXAMPLES:
##   my $iodef = (new XML::IODEF)->in("/home/user/iodef.xml");
##   $iodef = $iodef->in("<IODEF-Document version=\"1.0\"></IODEF-Document>");
##

sub in {
    my($iodef, $arg) = @_;
    my($doc, $parser, $x);

    # if no param, create empty XML::IODEF doc
    return new XML::IODEF if (!defined($iodef));
    return new XML::IODEF if (!defined($arg));

    # parse IODEF string or file
    $parser = XML::DOM::Parser->new;
    
    # is $arg an iodef string or a filepath? test if it starts with <
    $arg =~ / *(.)/;
    if ($1 eq "<") {
	$doc = $parser->parse($arg);
    } else {	
	$doc = $parser->parsefile($arg);
    }

    # check that the document has a DOCTYPE and an XML declaration
    #if (!defined($doc->getDoctype())) {
	#$x = $doc->createDocumentType($DOCTYPE_NAME, $DOCTYPE_SYSID, $DOCTYPE_PUBID); 
	#$doc->setDoctype($x);
    #}	
    
    if (!defined($doc->getXMLDecl())) {
		$x = $doc->createXMLDecl($XML_DECL_VER, $XML_DECL_ENC);
		$doc->setXMLDecl($x);
    }

    $iodef->{"DOM"} = $doc;

    return $iodef;
}



##----------------------------------------------------------------------------------------
##
## out(<hash>)
##
## ARGS:
##   <hash>  an XML::IODEF object
##
## RETURN:
##   a string containing the corresponding IODEF message
##
## EXAMPLES:
##    $string = $iodef->out();
##

sub out {
    my $iodef = shift;
    return $iodef->{"DOM"}->toString;
}



##----------------------------------------------------------------------------------------
##
## get_root(<iodef>)
##
## ARGS:
##   <iodef>  an XML::IODEF object
##
## RETURN:
##   a string representing the name of the root element of the IODEF message,
##   normally "IODEF-Document", or undef if no root element defined.
##
## EXAMPLES:
##   $iodef = new XML::IODEF();
##   $iodef->add("IncidentIncidentID", "#12345");
##   $root = $iodef->get_root();   # $type now contains the string "IODEF-Document"   
##

sub get_root {
    my $iodef = shift;
    
    my $c = $iodef->{"DOM"}->getDocumentElement();
    return $c->getTagName()
	if (defined($c));

    return undef;
}



##----------------------------------------------------------------------------------------
##
## get_type(<hash>)
##
## ARGS:
##   <iodef>  an XML::IODEF object
##
## RETURN:
##   a string representing the type of IODEF message ("Incident"...)
##   or undef if this message does not have a type yet.
##
## EXAMPLES:
##   $iodef = new XML::IODEF();
##   $iodef->add("IncidentIncidentID", "#12345");
##   $type = $iodef->get_type();   # $type now contains the string "Incident"   
##

sub get_type {
    my $iodef = shift;
    
    my $c = $iodef->{"DOM"}->getDocumentElement();
    return undef
	if (!defined($c));

    foreach my $n ($c->getChildNodes()) {
	return $n->getTagName()
	    if ($n->getNodeType() == ELEMENT_NODE);
    }

    return undef;
}



##----------------------------------------------------------------------------------------
##
## contains(<iodef>, <tagpath>)
## 
## ARGS:
##   iodef:    a hash representation of an IODEF message, as received from new or in
##   tagpath:  a string obtained by concatenating the names of the nested tags, from the
##             Incident tag down to the closest tag to value.
##
## RETURN: 
##   1 if there is at least one value set to the particular tagpath.
##   0 otherwise.
##

sub contains {
    my($iodef, $path) = @_;
    my($type, @tagpath, $dom, $att, $n);

    $path = $ROOT.$path;
    $dom = $iodef->{"DOM"}->getDocumentElement;

    return 0 if (!defined $dom);

    return 0 if (!exists($EXPAND_PATH->{$path}));

    ($type, @tagpath) = @{$EXPAND_PATH->{$path}};

    $att = pop @tagpath
	if ($type eq 'A');

    if ($type eq 'N' or $type eq 'C') {
	defined(find_node($dom, @tagpath)) ? return 1 : return 0;

    } elsif ($type eq 'A') {
	$n = find_node($dom, @tagpath);
	return 0 if (!defined($n));
	($n->getAttribute($att) ne "") ? return 1 : return 0;
    }

    croak "contains: internal error. found element of type $type.";
}



#----------------------------------------------------------------------------------------
#
# find_node($node, @tagpath)
#
# return the last node in @tagpath if @tagpath exists in $dom, 
# return undef otherwise
# @tagpath are the name of DOM::Elements inside $dom. no attribute.
# tagpath starts at the root (IODEF-Message)
# if the tagpath occurs multiple times, return the first occurence of it.
#

sub find_node {
    my($node, @tagpath) = @_;
    my($name, $n, $m);
    
    $name = substr(shift(@tagpath), 1);

    if ($node->getTagName() eq $name) {

	return $node
	    if ((scalar @tagpath) == 0);
	
	foreach $n ($node->getChildNodes()) {
	    if ($n->getNodeType() == ELEMENT_NODE) {
		$m = find_node($n, @tagpath);	
		if (defined($m)) {
		    return $m;
		}
	    }
	}	
    }
    
    return undef;
}




#----------------------------------------------------------------------------------------
#
# find_node_in_first_path($node, @tagpath)
#
# similar to find_node(), but look only through the first
# occurence of the tagpath. the node may hence exists somewhere else.
# return the last node in @tagpath if @tagpath exists in $dom, 
# return undef otherwise
#

sub find_node_in_first_path {
    my($node, @tagpath) = @_;
    my($tag, $name, $n, $next);

    $name = substr(shift @tagpath, 1);

    return undef
	if ($node->getTagName() ne $name);

    foreach $tag (@tagpath) {
	$name = substr($tag, 1);

	# find a child with right name
	$next = undef;
	foreach $n ($node->getChildNodes()) {
	    if ($n->getNodeType() == ELEMENT_NODE and $n->getTagName() eq $name) {
		$next = $n;
		last;
	    }
	}
	
	# next child not found
	return undef
	    if (!defined($next));
	
	$node = $next;
    }

    return $node;
}


##----------------------------------------------------------------------------------------
##
## add(hash, tagpath, value)
## 
## ARGS:
##   hash:    a hash representation of an IODEF message, as received from new or in
##   tagpath: a string obtained by concatenating the names of the nested tags, from the
##            Incident tag down to the closest tag to value.
##   value:   the value (content of a tag, or value of an attribute) of the last tag
##            given in tagpath
##
## RETURN:
##   0 if the field was correctly added, and croak otherwise (if you did
##   something that goes against the DTD).
##
## DESC:
##   Each IODEF field of a given IODEF message can be created through a corresponding add()
##   call. These interfaces are designed for easily building a new IODEF message while
##   parsing a log file. The 'tagpath' is the same as returned by the 'to_hash' call.
##
## RESTRICTIONS:
##   You cannot change an attribute value with add(). An attempt to run add() on an attribute 
##   that already exists will just be ignored. Contents cannot be changed either, but a new 
##   tag can be created if you are adding an iodef content that can occur multiple time (ex:
##   UserIdname, AdditionalData...).
##
## SPECIAL CASE: AdditionalData
##   AdditionalData is a special tag requiring at least 2 add() calls to build a valid node. In 
##   case of multiple AdditionalData delaration, take care of building AdditionalData nodes one 
##   at a time, and always begin by adding the "AddtitionalData" field (ie the tag's content).
##   Otherwise, the iodef key insertion engine will get lost, and you'll get scrap.
##
##   As a response to this issue, the 'add("IncidentAdditionalData", "value")' call accepts an
##   extended syntax compared with other calls:
##
##   add("IncidentAdditionalData", <value>);   
##      => add the content <value> to Incident/AdditionalData
##
##   add("IncidentAdditionalData", <value>, <meaning>); 
##      => same as:  (type string is assumed by default)
##         add("IncidentAdditionalData", <value>); 
##         add("IncidentAdditionalDatameaning", <meaning>); 
##         add("IncidentAdditionalDatadtype", "string");
##
##   add("IncidentAdditionalData", <value>, <meaning>, <type>); 
##      => same as: 
##         add("IncidentAdditionalData", <value>); 
##         add("IncidentAdditionalDatameaning", <meaning>); 
##         add("IncidentAdditionalDatadtype", <type>);
##
##   The use of add("IncidentAdditionalData", <arg1>, <arg2>, <arg3>); is prefered to the simple
##   add call, since it creates the whole AdditionalData node at once. In the case of 
##   multiple arguments add("IncidentAdditionalData"...), the returned value is 1 if the type key
##   was inserted, 0 otherwise.
##
##
## EXAMPLES:
##
##   my $iodef = new XML::IODEF();
##
##   $iodef->add("IncidentIncidentID", "<value>");     
##
##   $iodef->add($iodef, "Incidentrestriction", "<value>");
##
##   # AdditionalData case:
##   # DO:
##   $iodef->add("IncidentAdditionalData", "value");           # content add first
##   $iodef->add("IncidentAdditionalDatadtype", "string");      # ok
##   $iodef->add("IncidentAdditionalDatameaning", "meaning");  # ok
##
##   $iodef->add("IncidentAdditionalData", "value2");          # content add first 
##   $iodef->add("IncidentAdditionalDatadtype", "string");      # ok
##   $iodef->add("IncidentAdditionalDatameaning", "meaning2"); # ok
##
##   # or BETTER:
##   
##   $iodef->add("IncidentAdditionalData", "value", "meaning", "string");  # VERY GOOD
##   $iodef->add("IncidentAdditionalData", "value2", "meaning2");          # VERY GOOD (string type is default)
##
##
##   # DO NOT DO:
##   $iodef->add("IncidentAdditionalData", "value");           # BAD!! content should be declared first
##   $iodef->add("IncidentAdditionalDatameaning", "meaning2"); # BAD!! content first!
##
##   # DO NOT DO:
##   $iodef->add("IncidentAdditionalData", "value");           # BAD!!!!! mixing node declarations
##   $iodef->add("IncidentAdditionalData", "value2");          # BAD!!!!! for value & value2
##   $iodef->add("IncidentAdditionalDatadtype", "string");      # BAD!!!!! 
##   $iodef->add("IncidentAdditionalDatadtype", "string");      # BAD!!!!!

## TODO -- test ext-value and ext-dtype

sub add {
    my ($tag, $root, $dom, $c);
    my ($iodef, $path, $value, @tail) = @_;

    $path  = $ROOT.$path;
    $dom   = $iodef->{"DOM"};
    $root  = $dom->getDocumentElement;

    # create a root element if none exists
    if (!defined $root) {
	$root = $dom->createElement($ROOT);
	$dom->appendChild($root);
    }

    # is this a known tagpath?
    if (!exists($EXPAND_PATH->{$path})) {
	croak "add: $path is not a known IODEF tag path (IODEF v$IODEF_VERSION).";
    }

    # if it is an attribute or a content, did we get a value?
    $c = ${$EXPAND_PATH->{$path}}[0];
    croak "add: $path is an attribute or a content and requires a value (which you did not give)."
	if (($c eq 'A' or $c eq 'C') and !defined($value));

    # check if value is valid
    if (exists($CHECK_VALUE->{$path})) {
	check_allowed($path, $value, @{$CHECK_VALUE->{$path}});
    }

    # add key to path
    $tag = @{$EXPAND_PATH->{$path}}[3];

    # check if it is AdditionalData	
    ## TODO: check for ext-value settings
    if (defined($tag) && substr($tag,1) eq "AdditionalData") {
	
	if (scalar(@tail) == 0) {
	    add_in_dom($dom, $root, $path, $value);
	} elsif (scalar(@tail) == 1) {
	    add_in_dom($dom, $root, $path, $value);
	    add_in_dom($dom, $root, $path."meaning", $tail[0]);
	    add_in_dom($dom, $root, $path."dtype", "string");
	} elsif (scalar(@tail) == 2) {
	    check_allowed($path."type", $tail[1], @{$CHECK_VALUE->{$path."dtype"}});
	    add_in_dom($dom, $root, $path, $value);
	    add_in_dom($dom, $root, $path."meaning", $tail[0]); 	
	    add_in_dom($dom, $root, $path."dtype", $tail[1]);
	} else {
	    croak "add: wrong number of arguments given to add(\"$path\")";
	}
    }
    else
    {
	    add_in_dom($dom, $root, $path, $value);
    }

    return 0;
}



#----------------------------------------------------------------------------------------
#
# add_in_dom($root, $tagpath [, $value])
#
# if their is a value, add this value to the tagpath, otherwise add the 
# node pointed by tagpath. return the changed node.
#

sub add_in_dom {
    my($dom, $root, $path, $val) = @_;
    my($type, @tagpath, $att, $node, $text, $n);

    # find the tagpath corresponding to $path
    ($type, @tagpath) = @{$EXPAND_PATH->{$path}};

    if ($type eq 'N') {
	# we want to add a node
	$node = find_node_in_first_path($root, @tagpath);

	if (defined $node) {
	    return duplicate_node_path($dom, $root, @tagpath);
	} else {
	    return create_node_path($dom, $root, @tagpath);
	}

    } elsif ($type eq 'A') {
	# we want to add an attribute
	$att = pop @tagpath;
	$node = find_node_in_first_path($root, @tagpath);

	if (!defined $node) {
	    $node = create_node_path($dom, $root, @tagpath);
	} else {
	    # if attribute already set, try to duplicate node
	    if ($node->getAttribute($att) ne "") {
		$node = duplicate_node_path($dom, $root, @tagpath);
	    }
	}

	# add attribute
	$node->setAttribute($att, $val);

	return $node;

    } elsif ($type eq 'C') {
	# we want to add a content
	$node = find_node_in_first_path($root, @tagpath);

	# if node does not exists, create it
	if (!defined $node) {
	    $node = create_node_path($dom, $root, @tagpath);
	}

	
	# find this node's Text node
	foreach $n ($node->getChildNodes()) {
	    if ($n->getNodeType() == TEXT_NODE) {
		# node already has text child. duplicate node
		$n = duplicate_node_path($dom, $root, @tagpath);
		$node = $n;
		last;
	    }
	}

	# found a node that does not have any text element. create text.
	$n = $dom->createTextNode($val);
	$node->appendChild($n);

	return $node;
    }

    croak "add_in_dom: internal error. found element of type $type.";
}



#----------------------------------------------------------------------------------------
#
# create_node_path($root, @tagpath)
#
# create all nodes in @tagpath, and return the last node in tagpath.
# all nodes in @tagpath are elements. 
# create_node assumes that $root is a non null element, which usually
# implies that the iodef dom document should have a root.
#

sub create_node_path {
    my($dom, $root, @tagpath) = @_;
    @tagpath = map({substr($_,1)} @tagpath);
    return create_node_internal($dom, $root, @tagpath);
}

sub create_node_internal {
    my($dom, $node, @tagpath) = @_;
    my($name_node, $name_next, @child_order, $i, $pos, $next_child, $pos2, $name, $new, @a, $n);

    $name_node = shift @tagpath;
    $name_next = shift @tagpath;

    croak "create_node: got empty tagpath."
	if (!defined $name_node);

    return undef 
	if ($node->getTagName() ne $name_node);

    return $node
	if (!defined $name_next);

    # lookup children order for $name_node in DTD
    @child_order = @{$DTD->{$name_node}->{CHILDREN}};
    @child_order = map({substr $_, 1} @child_order);

    # this expression finds the offset in @children of the last occurence of $name_next
    for($pos=0, $i=0; $i < scalar(@child_order); $i++) {
	$pos = $i if ($child_order[$i] eq $name_next);
    }

    # go through all children, and insert new node before first following kid
    $next_child = undef;

    foreach $n ($node->getChildNodes()) {

	if ($n->getNodeType() == ELEMENT_NODE) {
	    $name = $n->getTagName;
	    
	    # if we found the node we searched, loop in it
	    if ($name eq $name_next) {
		return create_node_internal($dom, $n, $name_next, @tagpath);
	    }

	    # check if we found a node that should occur after the one to be inserted
	    # if so, break the loop and create a new node before it
	    for($pos2=0, $i=0; $i < scalar(@child_order); $i++) {
		if ($child_order[$i] eq $name) {
		    $pos2 = $i;
		    last;
		}
	    }

	    if ($pos2 > $pos) {
		$next_child = $n;
		last;
	    }
	}
    }

    # create a new node and insert it at the right place
    $new = $dom->createElement($name_next);
    $node->insertBefore($new, $next_child);

    return create_node_internal($dom, $new, $name_next, @tagpath);
}



#----------------------------------------------------------------------------------------
#
# duplicate_node_path($dom, $root, @tagpath)
#
# duplicate the last node in @tagpath, ie
# find the closest parent to that node that accepts multiple occurences
# of node path, create a new instance of the node, and call create_node 
# to recreate all elements down to the node. return the duplicated node
#

sub duplicate_node_path {
    my($dom, $root, @node_path) = @_;
    my($name, $node, $new, $next, $array, @tail, $i, $c, @array);

    # find the closest parent of last node, having multiple occurences
    for ($i = (scalar @node_path) - 1; $i > 0; $i--) {
	last if ($node_path[$i] =~ /^[\+\#\*]/);
    }

    croak "add - duplicate_node: could not duplicate node".(pop @node_path).". no duplicable parent."
	if ($i == 0);
    
    # duplicate the node at $i-2 in @node_path
    @tail = splice(@node_path, $i+1);
    $name = pop @node_path;

    # try to find the node to duplicate
    $node = find_node($root, @node_path, $name) ||
	croak "duplicate_node_path: did not find node to duplicate. impossible.";

    # create new instance of 'name' and insert before $node
    $new = $dom->createElement(substr($name, 1));
    $node->getParentNode()->insertBefore($new, $node);

    # build all node path in the original @node_path, and return the last
    return create_node_path($dom, $root, @node_path, $name, @tail);
}



#----------------------------------------------------------------------------------------
#
# check_allowed(path, key, @list);
#
# check that key is one element of list.
# returns 1 if it is, 0 if key is not in and
# croak
#

sub check_allowed {
    my($path, $key, $v, @vals);
    ($path, $key, @vals)= @_;

    foreach $v (@vals) {
	return 1 if ($v eq $key);
    }

    croak "add: $key is not an allowed value for attribute $path (IODEF v$IODEF_VERSION).";
    return 0;
}



##----------------------------------------------------------------------------------------
##
## set(hash, tagpath, value)
## 
## ARGS:
##   hash:    a hash representation of an IODEF message, as received from new or in
##   tagpath: a string obtained by concatenating the names of the nested tags, from the
##            Incident tag down to the closest tag to value.
##   value:   the value (content of a tag, or value of an attribute) of the last tag
##            given in tagpath
##
## RETURN:
##   0 if the field was correctly changed, croaks otherwise.
##
## DESC:
##   The set() call follows the first occurence of the node path described by
##   <tagpath> and attempts at changing the corresponding content or attribute value.
##   If the first occurence of <tagpath> does not lead to any existing node, set()
##   croaks. Check that the node or attribute exists with contains() first.
##   If you want to create an attribute value or a node content where there was none,
##   use add() instead.
##   
## RESTRICTIONS:
##   set() only allows you to reach and change the attribute or content of the first
##   occurence of a given tagpath. If this tagpath occurs multiple time, you will 
##   not be able to modify the other occurences. Yet this should be able for most
##   applications. Furthermore, set() cannot be used to create any new value/content.
##
## EXAMPLES:
##
##   my $iodef = new XML::IODEF();
##
##   $iodef->add("IncidentAdditionalData", "value");           # content add first
##   $iodef->add("IncidentAdditionalDatadtype", "string");      # ok
##   $iodef->add("IncidentAdditionalDatameaning", "meaning");  # ok
##
##   # change AdditionalData's content value
##   $iodef->set("IncidentAdditionalData", "new value");
##

sub set {
    my($iodef, $path, $value) = @_;
    my($root, $type, $att, @tagpath, $node, $n);

    # did we get a path?
    croak "set: you did not give any path."
	if (!defined($path));

    $path  = $ROOT.$path;
    $root  = $iodef->{"DOM"}->getDocumentElement;

    # is this a known tagpath?
    croak "set: $path is not a known IODEF tag path (IODEF v$IODEF_VERSION)."
	if (!exists($EXPAND_PATH->{$path}));
    
    # is it a content or attribute?
    ($type, @tagpath) = @{$EXPAND_PATH->{$path}};

    croak "set: $path does not lead to an attribute nor to an authorized node content."
        if ($type eq 'N');
    
    # did we get a value?
    croak "set: you did not provide any value."
        if (!defined($value));
    
    # check if value is valid
    if (exists($CHECK_VALUE->{$path})) {
	check_allowed($path, $value, @{$CHECK_VALUE->{$path}});
    }
    
    $att = pop @tagpath
	if ($type eq 'A');

    $node = find_node($root, @tagpath);

    # if node does not exists, croaks
    croak "set: there is no node at path $path. use add() first."
	if (!defined($node));

    # let's change the content or attribute
    if ($type eq 'A') {

	# does the attribute exists?
	croak "set: the attribute at path $path has no value. use add() first."
	    if ($node->getAttribute($att) eq "");

	# set its value
	$node->setAttribute($att, $value);
	return 0;

    } elsif ($type eq 'C') {

	# does this node has a text node?
	foreach $n ($node->getChildNodes()) {	    
	    if ($n->getNodeType() == TEXT_NODE) {  
		$n->setData($value);
		return 0;
	    }
	}

	croak "set: the node at path $path has no content. use add() first.";
    }
    
    # should never reach here
    croak "set: internal error.";
}



##----------------------------------------------------------------------------------------
##
## get(hash, tagpath, value)
## 
## ARGS:
##   hash:    a hash representation of an IODEF message, as received from new or in
##   tagpath: a string obtained by concatenating the names of the nested tags, from the
##            Incident tag down to the closest tag to value.
##   value:   the value (content of a tag, or value of an attribute) of the last tag
##            given in tagpath
##
## RETURN:
##   a string: the content of the node or value of the attribute, undef if there is
##   no such value, and croaks if error.
##
## DESC:
##   The get() call follows the first occurence of the node path described by
##   <tagpath> and attempts at retrieving the corresponding content or attribute value.
##   If the first occurence of <tagpath> does not lead to any existing node, get()
##   returns undef. But this does not mean that the value does not exists in an other
##   occurence of the pagpath.
##   
## RESTRICTIONS:
##   get() only allows you to reach and retrieve the attribute or content of the first
##   occurence of a given tagpath. If this tagpath occurs multiple time, you will 
##   not be able to retrieve the other occurences. Yet this should be able for most
##   applications.
##
## EXAMPLES:
##
##   my $iodef = new XML::IODEF();
##
##   $iodef->add("IncidentAdditionalData", "value");           # content add first
##   $iodef->add("IncidentAdditionalDatadtype", "string");      # ok
##   $iodef->add("IncidentAdditionalDatameaning", "meaning");  # ok
##
##   # change AdditionalData's content value
##   $iodef->get("IncidentAdditionalData");
##

sub get {
    my($iodef, $path, $value) = @_;
    my($root, $type, $att, @tagpath, $node, $n);

    # did we get a path?
    croak "get: you did not give any path."
	if (!defined($path));

    $path  = $ROOT.$path;
    $root  = $iodef->{"DOM"}->getDocumentElement;

    # is this a known tagpath?
    croak "get: $path is not a known IODEF tag path (IODEF v$IODEF_VERSION)."
	if (!exists($EXPAND_PATH->{$path}));
    
    # is it a content or attribute?
    ($type, @tagpath) = @{$EXPAND_PATH->{$path}};

    croak "get: $path does not lead to an attribute nor to an authorized node content."
        if ($type eq 'N');
    
    $att = pop @tagpath
	if ($type eq 'A');

    $node = find_node($root, @tagpath);

    # if node does not exists, return undef
    return undef
	if (!defined($node));

    # let's fetch the content or attribute
    if ($type eq 'A') {
	return $node->getAttribute($att);

    } elsif ($type eq 'C') {

	# does this node has a text node?
	foreach $n ($node->getChildNodes()) {	    
	    if ($n->getNodeType() == TEXT_NODE) {  
		return $n->getData;
	    }
	}

	return undef;
    }
    
    # no content in this node
    return undef;
}



##----------------------------------------------------------------------------------------
##
## create_ident(<iodef>) -- deprecated
##
## ARGS:
##   <iodef>       iodef message object
##
## RETURN: 
##   nothing.
##
## DESC:
##   Set the root ident attribute field of this IODEF message with a unique,
##   randomly generated ID number. The code for the ID number generator is actually 
##   inspired from Sys::UniqueID. If no IODEF type is given, "Incident" is assumed as default.
##

sub create_ident {
    my($id, $iodef, $name, $netaddr);
    $iodef = shift;

    warn 'create_ident is deprecated, you should be using your domain-name in conjuction with the ID from your workflow system';
    
    $name = $iodef->get_type();
    $name = "Incident" if (!defined $name);

    # code cut n paste from Sys::UniqueID. replaced IP with random number.
    # absolutely ensure that id is unique: < 0x10000/second
    $netaddr = int(rand 10000000);

    unless(++$ID_COUNT < 0x10000) { sleep 1; $ID_COUNT= 0; }
    $id =  sprintf '%012X%s%08X%04X', time, $netaddr, $$, $ID_COUNT;

    $iodef->add($name."IncidentID", $id);        
}



##----------------------------------------------------------------------------------------
##
## create_time(<iodef>, [<epoch>])
##
## ARGS:
##   <iodef>       iodef message object
##   <epoch>       optional. epoch time (time since January 1, 1970, UTC).
##
## RETURN: 
##   nothing.
##
## DESC:
##   Set the CreateTime field of this iodef message with the current time
##   (if no epoch argument if provided), or to the time corresponding to
##   the epoch value provided, in both the content and ntpstamp fields. 
##   If the IODEF message does not yet have a type, "Incident" is assumed by
##   default.
##

sub create_time {
    my $iodef = shift;
    my $utc   = shift || time(); 
    
    my $timestamp = DateTime->from_epoch(epoch => $utc);
    add($iodef,'IncidentReportTime',$timestamp.'Z');
}

##----------------------------------------------------------------------------------------
##
## to_hash(<hash>)
##
## ARGS:
##   <hash>  hash containing an IODEF message in XML::Simple representation
##
## RETURN:
##   a hash enumerating all the contents and attributes of this IODEF message.
##   each key is a concatenated sequence of tags leading to the content/attribute,
##   and the corresponding value is the content/attribute itself.
##   all IODEF contents and values are converted from IODEF format (STRING or BYTE)
##   back to the original ascii string.
##
## EXAMPLES:
##
## <IODEF-Document version="1.0">
##  <Incident purpose="handling">
##    <IncidentID>
##      #12345 
##    </IncidentID>
##    <AdditionalData meaning="datatype1">data1</AdditionalData>
##    <AdditionalData meaning="datatype2">data2</AdditionalData>
##  </Incident>
## </IODEF-Document>
##
## becomes:
##
## { "version"                       => [ "1.0" ],
##   "Incidentpurpose"               => [ "handling" ],
##   "IncidentIncidentID"            => [ "#12345" ],
##   "IncidentAdditionalDatameaning" => [ "datatype1", "datatype2" ],   #meaning & contents are
##   "IncidentAdditionalData"        => [ "type1", "type2" ],           #listed in same order
## }
##
##

sub to_hash {
    my $iodef  = shift;
    my $result = {};
    my $root   = $iodef->{"DOM"}->getDocumentElement;

    dom_to_hash($root, $result, "");

    return $result;
}

# there's probably a 'better' way to do this wihtin DOM
# but who has that kind of time with XML::Simple :)
sub to_tree {
    my $iodef = shift;
    return(XMLin($iodef->out()));
}
    

#----------------------------------------------------------------------------------------
#
# dom_to_hash($node, $result, $path)
#
# explore node and add its attributes and content to $result, and
# explore recursively each of node's children.
#

sub dom_to_hash {
    my($node, $result, $path) = @_;
    my($n, $type);

    return if (!defined($node));

    # explore node's attributes
    foreach $n ($node->getAttributes->getValues) {
		add_to_result($result, $path.$n->getName, $n->getValue);	    
    }

    # explore node's children
    foreach $n ($node->getChildNodes()) {

	$type = $n->getNodeType();

	if ($type == TEXT_NODE) {	    
	    # first check if the DTD accepts content for this node
	    # this is to avoid all the '\n' that DOM::Parser consider
	    # as content.
	    if (@{$EXPAND_PATH->{$ROOT.$path}}[0] eq 'C') {
		add_to_result($result, $path, $n->getData);
	    }
	} elsif ($type == ELEMENT_NODE) {
	    dom_to_hash($n, $result, $path.$n->getTagName);
	}
    }
}

sub add_to_result {
    my($result, $path, $val) = @_;

    if (exists($result->{$path})) {
	push @{$result->{$path}}, $val;
    } else {
	$result->{$path} = [ $val ];
    }
}



##=========================================================================================
##
##  BACKWARD COMPATIBILIY FUNCTIONS 
##
##=========================================================================================

##
##
## CLASS FUNCTIONS:
## ----------------
##

# wrapper for contains()
sub at_least_one {
    return contains(@_);
}

##
##
## EXPORTED FUNCTIONS:
## -------------------
##

# wrapper for extend_dtd()
sub extend_iodef {   extend_dtd(@_); }

##----------------------------------------------------------------------------------------
##
## <byte_string> = byte_to_string(<bytes>)
##
## ARGS:
##   <bytes>    a binary string
##
## RETURN:
##   <byte_string>: the string obtained by converting <bytes> into its IODEF representation,
##   refered to as type BYTE[] in the IODEF rfc.
##

sub byte_to_string {
    return join '', map( { "&\#$_;" } unpack("C*", $_[0]) ); 
}

##----------------------------------------------------------------------------------------
##
## <xmlstring> = xml_encode(<string>)
##
## ARGS:
##   <string>   a usual string
##
## RETURN:
##   <xmlstring>: the xml encoded string equivalent to <string>. 
##
## DESC:
##   You don't need this function if you are using add() calls (which already calls it).
##   To convert a string into an iodef STRING, xml_encode basically replaces
##   characters:         with:
##         &                 &amp;
##         <                 &lt;
##         >                 &gt;
##         "                 &quot;
##         '                 &apos;
##   and all non printable characters (ie charcodes >126 or <32 except 10) into
##   the corresponding &#x00XX; form.
##

# create a lookup array, start with filling it with xml encoded chars 
my @xml_enc = map { sprintf("&\#x00%.2x;", $_) } 0..255;
    
# map the printable characters to themselves
# NOTE: XML standard says encode all chars < 32 except 10, and all > 126 
for (10,32..126) {
    $xml_enc[$_] = chr($_);
}

# the special xml characters maps to their own encodings
$xml_enc[ord('&')]  = "&amp;";
$xml_enc[ord('<')]  = "&lt;";
$xml_enc[ord('>')]  = "&gt;";
$xml_enc[ord('"')]  = "&quot;";
$xml_enc[ord('\'')] = "&apos;";

sub xml_encode {
    my ($st) = @_;
    return join('', map { $xml_enc[ord($_)]} ($st =~ /(.)/gs));
}

##----------------------------------------------------------------------------------------
##
## <string> = xml_decode(<xmlstring>)
##
## ARGS:
##   <xmlstring>  a xml encoded IODEF STRING
##
## RETURN:
##   <string>     the corresponding decoded string
##
## DESC:
##   You don't need this function with 'to_hash' (which already calls it).
##   It decodes <xmlstring> into a string, ie replace the following
##   characters:         with:
##         &amp;              &
##         &lt;               <
##         &gt;               >
##         &quot              "
##         &apos              '
##         &#XX;              XX in base 10
##         &#xXXXX;           XXXX in base 16
##   It also decodes strings encoded with 'byte_to_string'
##

sub xml_decode {
    my ($st) = @_;

    if (defined $st) {
	
	$st =~ s/&amp\;/&/gs;
	$st =~ s/&lt\;/</gs;
	$st =~ s/&gt\;/>/gs;
	$st =~ s/&quot\;/\"/gs;
	$st =~ s/&apos\;/\'/gs;
	
	$st =~ s/&\#x(.{4});/chr(hex $1)/ges;
	$st =~ s/&\#(.{2,3});/chr($1)/ges;
    }

    return $st;
}



#----------------------------------------------------------------------------------------
#
# END OF CODE - START OF POD DOC
#
#----------------------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

XML::IODEF - A module for building/parsing IODEF messages

=head1 QUICK START

Below is an example of an Incident IODEF message.


  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE IODEF-Message PUBLIC "-//IETF//DTD RFC 5070 IODEF v1.0//EN" "IODEF-Document.dtd">
  <IODEF-Document>
    <Incident purpose="reporting">
      <IncidentID>
	#12345
      </IncidentID>
      <AdditionalData meaning="data2" dtype="string">value2</AdditionalData>
      <AdditionalData meaning="data1" dtype="string">value1</AdditionalData>
    </Incident>
  </IODEF-Document>


The previous IODEF message can be built with the following code snipset:

    use XML::IODEF;   

    my $iodef = new XML::IODEF();  

    $iodef->add("Incidentpurpose", "reporting");
    $iodef->add("IncidentAdditionalData", "value1", "data1"); 
    $iodef->add("IncidentAdditionalData", "value2", "data2");
    $iodef->add("IncidentIncidentID", "#12345");

    print $iodef->out();

To automatically insert an the ReportTime class to the current time, add the line:

    $iodef->create_time();

and you will get (for example):

  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE IODEF-Message PUBLIC "-//IETF//DTD RFC 5070 IODEF v1.0//EN" "IODEF-Document.dtd">
  <IODEF-Document>
    <Incident purpose="reporting">
      <IncidentID>
	#12345
      </IncidentID>
	<ReportTime>2009-12-31T18:00:58Z</ReportTime>
      <AdditionalData meaning="data2" type="string">value2</AdditionalData>
      <AdditionalData meaning="data1" type="string">value1</AdditionalData>
    </Incident>
  </IODEF-Document>


=head1 WARNING
 
This RFC release was a complete restructuring from the draft XML::IODEF v0.06 was based on. THIS MODULE WILL PROBABLY BREAK YOUR EXISTING XML::IODEF CODE due to this restructuring. YOU SHOULD TEST AND RETEST BEFORE DEPLOYING INTO PRODUCTION!
 
=head1 DESCRIPTION

IODEF.pm is an interface for simply creating and parsing IODEF messages. IODEF is an XML based protocol designed mainly for representing computer security incidents (http://www.ietf.org/html.charters/inch-charter.html).

IODEF.pm is compliant with IODEF v1.0.
    
This API has been designed for simplifying the task of translating a key-value based format to its iodef representation. A typical session involves the creation of a new IODEF message, the initialisation of some of its fields and the addition of new IODEF tags to this message, while parsing some other native message.  IODEF.pm is heavily based on XML::IDMEF.  The only changes are the DTD definition, and modifications to check_xml_dtd and fill_internal_hashes to allow for limited recursion.  The maximum depth of recursion can be modified by changing $MAX_ITER (default 10).

An interface to load and parse an IODEF message is also provided.

The API used in XML::IODEF is in no way standard. It does not follow any of the SAX or DOM philosophy, since it is neither based on a tree representation nor on an event oriented parser (at least as seen from the outside). It instead gives a linear approach toward the XML object, and uses inbuilt knowledge about a given XML DTD (IODEF in our case) to make proper choices when building the message. This simplifies the task of building well formed XML messages, by taking care on your behalf of tasks such as building intermediary nodes in an XML tree, or inserting nodes in the right, DTD compliant order.

This module contains a generic XML DTD parser and includes a simplified node based representation of the IODEF DTD. It can hence easily be upgraded or extended to support new XML nodes or other DTDs. For information on how to use the XML::IODEF API with other XML DTDs, read the documentation in the source code :) Yet, beware that the internal DTD representation is a *simplified* DTD, and can not translate all the subtilities that may be defined in XML DTDs. This representation is enough for representing most simple DTDs, such as IODEF, but not for more complex DTDs. In particular, it considers all attributes as of type CDATA, and does not support complex children ordering and occurence policies.
    
This code is distributed under the BSD license.

=head1 EXPORT

    extend_dtd	
    set_doctype_name
    set_doctype_sysid
    set_doctype_pubid

=head1 AUTHORS

 John Green - johng@cpan.org (Original) 
 Wes Young  - wes@barely3am.com  (2007 Update -- RFC 5070)

=head1 LICENSE

This code is released under the BSD license.

=head1 SEE ALSO

 XML::DOM, XML::Parser, DateTime
 http://tools.ietf.org/html/rfc5070
 http://code.google.com/p/perl-xml-iodef

=head1 SYNOPSIS

In the following, function calls and function parameters are passed in a perl object-oriented fashion. Hence, some functions (object methods) are said to not take any argument, while they in fact take an IODEF object as first argument. Refer to the examples in case of confusion. The functions listed at the end (C<xml_encode>, C<xml_decode>, C<byte_to_string> are on the other hand class methods, and should not be called on an IODEF object.

Rather than returning with non null error codes, these API calls will raise an exception if an error is encountered. These exceptions will either come from XML::DOM or XML::IODEF, depending on at which level they occured. Exceptions generated by XML::IODEF are normally caused by you trying to create an XML message that is not a valid IODEF message. In practice, it means these methods will croak if you try to do something that goes against the IODEF DTD. So take care of putting all your IODEF generation code inside 'eval {};' blocks.


=head1 OBJECT METHODS

=head2 B<new>()

=over 4

=item B<ARGS> none.

=item B<RETURN>

a new empty IODEF message.

=item B<DESC>

C<new> creates and returns a new empty but valid IODEF message, ie containing an xml and a doctype declarations. Use C<add()> and C<create_time()> to add fields to this message.

=item B<EXAMPLES>

 my $iodef = new XML::IODEF;

=back  




=head2 $iodef->B<in>([PATH|STRING])

=over 4

=item B<ARGS>

I<PATH|STRING>: either an IODEF message as a string or a path to a file containing an IODEF message.

=item B<RETURN>

the IODEF object corresponding to this IODEF message.

=item B<DESC>

C<in> creates a new IODEF message from either a string C<STRING> or a file located at the path C<PATH>. If no argument is provided, an empty IODEF message is created and returned. If the parsed message does not contain any xml or doctype declarations, the missing declarations will be added.

=item B<EXAMPLES>

 my $iodef = (new XML::IODEF)->in("iodef.file");
 my $iodef = $iodef->in("<IODEF-Document/>");

=back




=head2 $iodef->B<out>()

=over 4
 
=item B<ARGS> none.

=item B<RETURN>
   
a string representing this IODEF object.

=item B<DESC>
   
C<out> returns the IODEF message as a string.

=item B<EXAMPLES>
   
 print $iodef->out;

=back



=head2 $iodef->B<create_time>([$epoch])

=over 4

=item B<ARGS>

I<$epoch>: optional. an epoch time (time in secunds since January 1, 1970, UTC).

=item B<RETURN> nothing.

=item B<DESC>  
   
C<create_time> sets the IODEF ReportTime node to the current time (if no epoch argument is provided), or to the time corresponding to the epoch value provided. It sets both the ntpstamp and the UTC time stamps of ReportTime.

=item B<EXAMPLES>
   
 $iodef->create_time();

=back




=head2 $iodef->B<get_type>()

=over 4

=item B<ARGS> none.

=item B<RETURN>
   
the type of this IODEF message, as a string.

=item B<DESC>
   
C<get_type> returns the type of this IODEF message as a string. An 'Incident' IODEF message would for example return "Incident".

=item B<EXAMPLES>
   
 $string_type = $iodef->get_type();

=back 




=head2 $iodef->B<add>($tagpath, $value)

=over 4

=item B<ARGS>

I<$iodef>: a hash representation of an IODEF message, as received from C<new> or C<in>.

I<$tagpath>: a string obtained by concatenating the names of the nested XML tags, from the Incident tag down to the closest tag to value.

I<$value>: the value (content of a tag, or value of an attribute) of the last tag given in tagpath.

=item B<RETURN>
   
0 if the field was correctly added. Otherwise it croaks, because the node you wanted to add goes against the IODEF DTD. Use 'eval {};' blocks to catch this exceptions.

=item B<DESC>

Each IODEF content/value of a given IODEF message node can be created through an appropriate add() call. A 'tagpath' is a string obtained by concatenating the names of the XML nodes from the top 'Incident' node down to the attribute or content whose value we want to set. Hence, in the example given in introduction, the tagpath for setting the value of the Incident purpose attribute is 'Incidentpurpose'.

The C<add> call was designed for easily building a new IODEF message while parsing a log file, or any data based on a key-value format.

=item B<DISCUSSION>

C<add> is used for creating all the nodes along a given tag path, and setting the content of the last node, or one of its attributes. C<add> can also be used to create a new empty IODEF node by calling C<add> with the appropriate tag path and no value.

When one tag path occurs multiple times in an IODEF object, the C<add> calls only affects the last one created.

=item B<DUPLICATED TAG PATH>

C<add> cannot be used to change the value of an already existing content or attribute. If you run C<add> on an attribute that already exists, XML::IODEF will try to duplicate one of the parent nodes of the attribute, and set the attribute to the new node hence created. If the IODEF DTD does not allow this node path to be duplicated, XML::IODEF croaks. The same stands true when trying to add a content to a node path where the node already has a content. XML::IODEF will try to duplicate this node path. 

=item B<SPECIAL CASE: AdditionalData>

AdditionalData is a special tag requiring at least 2 add() calls to build a valid node. In case of multiple AdditionalData delarations, take care of building AdditionalData nodes one at a time.

As a response to this issue, the 'add("IncidentAdditionalData", "value")' call accepts an extended syntax compared with other calls:

   add("IncidentAdditionalData", <value>);   
      => add the content <value> to Incident AdditionalData

   add("IncidentAdditionalData", <value>, <meaning>); 
      => same as:  (type "string" is assumed by default)
         add("IncidentAdditionalData", <value>); 
         add("IncidentAdditionalDatameaning", <meaning>); 
         add("IncidentAdditionalDatadtype", "string");

   add("IncidentAdditionalData", <value>, <meaning>, <dtype>); 
      => same as: 
         add("IncidentAdditionalData", <value>); 
         add("IncidentAdditionalDatameaning", <meaning>); 
         add("IncidentAdditionalDatadtype", <dtype>);

The use of add("IncidentAdditionalData", <arg1>, <arg2>, <arg3>) is prefered to the simple C<add> call, since it creates the whole AdditionalData node at once. In the case of multiple arguments C<add("IncidentAdditionalData"...)>, the returned value is 1 if the type key was inserted, 0 otherwise.

=item B<EXAMPLES>

 my $iodef = new XML::IODEF();

 $iodef->add("IncidentIncidentID", "<value>");     

 $iodef->add($iodef, "Incidentpurpose", "<value>");

 # AdditionalData case:
 # DO:
 $iodef->add("IncidentAdditionalData", "value");           # creating first AdditionalData node
 $iodef->add("IncidentAdditionalDatadtype", "string");      
 $iodef->add("IncidentAdditionalDatameaning", "meaning");  

 $iodef->add("IncidentAdditionalData", "value2");          # creating second AdditionalData node
 $iodef->add("IncidentAdditionalDatadtype", "string");      
 $iodef->add("IncidentAdditionalDatameaning", "meaning2"); 

 # or BETTER:
 $iodef->add("IncidentAdditionalData", "value", "meaning", "string");  
 $iodef->add("IncidentAdditionalData", "value2", "meaning2");          

=back




=head2 $iodef->B<set>($tagpath, $value)

=over 4

=item B<ARGS>

I<$iodef>: a hash representation of an IODEF message, as received from C<new> or C<in>.

I<$tagpath>: a string obtained by concatenating the names of the nested XML tags, from the Incident tag down to the closest tag to value, and leading to either a valid IODEF attribute or a valid content node.

I<$value>: the value (content of a tag, or value of an attribute) of the last tag given in tagpath.

=item B<RETURN>
   
0 if the field was correctly changed. Otherwise it croaks, because the node you wanted to add goes against the IODEF DTD. Use 'eval {};' blocks to catch this exceptions.

=item B<DESC>

The C<set()> call follows the first occurence of the node path described by <tagpath> and attempts at changing the corresponding content or attribute value. If the first occurence of <tagpath> does not lead to any existing node or attribute, set() croaks. Check first with C<contains()> that the node or attribute exists. If you want to create an attribute value or a node content where there was none, use C<add()> and not C<set()>.

=item B<RESTRICTIONS>

C<set()> only allows you to reach and change the attribute or content of the first occurence of a given tagpath (ie the last one created). If this tagpath occurs multiple time, you will  not be able to modify the other occurences. Yet this should be able for most applications. Furthermore, C<set()> cannot be used to create any new value/content.

=item B<EXAMPLES>

 my $iodef = new XML::IODEF();

 $iodef->add("IncidentAdditionalData", "value");           # content add first
 $iodef->add("IncidentAdditionalDatadtype", "string");      # ok
 $iodef->add("IncidentAdditionalDatameaning", "meaning");  # ok

 # change AdditionalData's content value
 $iodef->set("IncidentAdditionalData", "new value");

=back



=head2 $iodef->B<get>($tagpath)

=over 4

=item B<ARGS>

I<$iodef>: a hash representation of an IODEF message, as received from C<new> or C<in>.

I<$tagpath>: a string obtained by concatenating the names of the nested XML tags, from the Incident tag down to the closest tag to value, and leading to either a valid IODEF attribute or a valid content node.

=item B<RETURN>

a string: the content of the node or value of the attribute, undef if there is no such value, and croaks if error.
   
=item B<DESC>
   
The C<get()> call follows the first occurence of the node path described by I<$tagpath> and attempts at retrieving the corresponding content or attribute value. If the first occurence of I<$tagpath> does not lead to any existing node, C<get()> returns undef. But this does not mean that the value does not exists in an other occurence of the pagpath.

C<get()> only allows you to reach and retrieve the attribute or content of the first occurence of a given tagpath. If this tagpath occurs multiple time, you will not be able to retrieve the other occurences. Yet this should be able for most applications. 

=item B<EXAMPLES>

 my $iodef = new XML::IODEF();

 $iodef->add("IncidentAdditionalData", "value", "meaning"); 

 # get AdditionalData's content value
 $iodef->get("IncidentAdditionalData");

=back




=head2 $iodef->B<contains>($tagpath)

=over 4

=item B<ARGS> 

I<$tagpath>: a tagpath (see C<add>).

=item B<RETURN>
   
1 if there exists in this iodef message a value associated to the given tagpath. 0 otherwise.

=item B<DESC>
   
C<contains> is a test function, used to determine whether a value has already been set at a given tagpath.

=back




=head2 $iodef->B<to_hash>()

=over 4

=item B<ARGS> none.

=item B<RETURN>
   
the IODEF message flattened inside a hash.

=item B<DESC>
   
C<to_hash> returns a hash enumerating all the contents and attributes of this IODEF message. Each key is a concatenated sequence of XML tags (a 'tagpath', see C<add()>) leading to the content/attribute, and the corresponding value is an array containing the content/attribute itself. In case of multiple occurences of one 'tagpath', the corresponding values are listed as elements of the array (See the example).

=item B<EXAMPLES>

 <IODEF-Document version="1.0">
   <Incident purpose="mitigation">
     <IncidentID>
       #12345
     </IncidentID>
     <AdditionalData meaning="datatype1">data1</AdditionalData>
     <AdditionalData meaning="datatype2">data2</AdditionalData>
   </Incident>
 </IODEF-Document>
 
 becomes:
  
 { "version"                       => [ "1.0" ],
   "Incidentpurpose"               => [ "mitigation" ],
   "IncidentIncidentID"            => [ "#12345" ],
   "IncidentAdditionalDatameaning" => [ "datatype1", "datatype2" ],   # meaning & contents are
   "IncidentAdditionalData"        => [ "type1", "type2" ],           # listed in same order
 }

=back




=head1 CLASS METHODS

=head2 COMMENT

The following class methods are designed to access the DTD and XML engine on top of which XML::IODEF is built. These calls allows you to use the XML::IODEF API calls to generate/parse other XML formats than IODEF, by loading a given DTD representation into XML::IODEF and changing the corresponding DOCTYPE declarations. Avoid using these calls if you can, as they are little documented and subject to changes. No support will be provided on how to use them, and the documentation lies in the source code :) 


=head2 B<set_doctype_name>($string)

=over 4

=item B<ARGS>
   
I<$string>: a DOCTYPE name

=item B<DESC>
   
Sets the name field in the XML DOCTYPE declaration of XML messages generated by XML::IODEF. 'IODEF-Document' is the default.

=back




=head2 B<set_doctype_sysid>($string)

=over 4

=item B<ARGS>
   
I<$string>: a DOCTYPE system ID

=item B<DESC>
   
Sets the system ID field in the XML DOCTYPE declaration of XML messages generated by XML::IODEF. 'IODEF-Document.dtd' is the default.

=back




=head2 B<set_doctype_pubid>($string)

=over 4

=item B<ARGS>
   
I<$string>: a DOCTYPE public ID

=item B<DESC>
   
Sets the public ID field in the XML DOCTYPE declaration of XML messages generated by XML::IODEF. '-//IETF//DTD RFC 5070 IODEF v1.0//EN' is the default.

=back




=head2 B<extend_dtd>($IODEF-class, $Extended-subclass)

=over 4

=item B<ARGS>
   
I<$IODEF-class>: a pseudo representation of an XML DTD that either extands IODEF or represent a completly different XML protocol.
    
I<$Extended-subclass>: the name of the new DTD's root. 'IODEF-Document' is the default if no value provided.

=item B<RETURN> nothing. croaks if the provided pseudo-DTD contains incoherencies.

=item B<DESC>

C<extend_dtd> is used to extend the IODEF DTD by changing the definition of some IODEF nodes and/or adding newnodes. It can also be used to load a completly new DTD representation in XML::IODEF's XML engine, hence making it possible to use the XML::IODEF API to generate and parse other XML formats then IODEF.
Internally, the IODEF.pm module is built around a DTD parser, which reads an XML DTD (written in a proprietary but straightforward format) and provides calls to build and parse XML messages compliant with this DTD. This DTD parser and its API could be used for (almost) any other XML format than IODEF, provided that the appropriate DTD gets loaded in the module, and that the DTD can be represented in the pseudo-DTD format used internally by the module. 
The format of the pseudo-DTD representation is complex and subject to changes. Yet, if you really wish to use these functionalities, you will find proper documentation in the module source code.

Example: to add a new node called hexdata to the AdditionalData node, do:
 
    my $ext_dtd = {
        "AdditionalData" => {
            ATTRIBUTES  => { 
                "dtype" => ["boolean", "byte", "character", "date-time", "integer", "portlist",
                "real", "string", "file", "frame", "packet", "ipv4-packet", "ipv6-packet",
                "path", "url", "csv", "winreg", "xml", "ext-value"],
                "ext-dtype"    => [],
                "meaning"      => [],
                "formatid"     => [],
                "restriction" => [ "public", "need-to-know", "private", "default" ],
            },
            CONTENT => 'ANY',
            CHILDREN    => [ "hexdata" ],
        },
        "hexdata"   => { CONTENT => PCDATA },
    };
    extend_dtd($ext_dtd, "IODEF-Document");

=back

=cut
























