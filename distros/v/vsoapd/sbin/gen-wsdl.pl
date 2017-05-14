#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use warnings;
use strict;

# Copyright (c) 2006 Randy Smith
# $Id: gen-wsdl.pl,v 1.5 2007/01/15 21:43:50 perlstalker Exp $

our $VERSION = "0.1.0";

our $DEBUG = 0;
my $c_sec = 'vsoapd';

use FindBin;

BEGIN {

    our @etc_dirs = (
		             "$FindBin::Bin/../etc",
		             "$FindBin::Bin",
		             "$FindBin::Bin/..",
                     "$FindBin::Bin/vuser",
                     "$FindBin::Bin/../vuser",
                     "$FindBin::Bin/../etc/vuser",
                     '/usr/local/etc',
		             '/usr/local/etc/vuser',
		             '/etc',
		             '/etc/vuser',
                     );
}

use vars qw(@etc_dirs);

use Config::IniFiles;
use Getopt::Long;

use lib (map { "$_/extensions" } @etc_dirs);
use lib (map { "$_/lib" } @etc_dirs);

use VUser::ExtLib qw(:config);
use VUser::ExtHandler;
use VUser::Log qw(:levels);
use VUser::Meta;

my $config_file;
my $debug = 0;
my @keywords = ();
my $result = GetOptions( "config=s" => \$config_file,
                         "debug|d+" => \$debug,
                         "keywords=s" => \@keywords
                        );

if( defined $config_file )
{
    die "FATAL: config file: $config_file not found" unless( -e $config_file );
}
else
{
    for my $etc_dir (@etc_dirs)
    {
	if (-e "$etc_dir/vuser.conf") {
	    $config_file = "$etc_dir/vuser.conf";
	    last;
	}
    }
}

if (not defined $config_file) {
    die "Unable to find a vuser.conf file in ".join (", ", @etc_dirs).".\n";
}

my %cfg;
tie %cfg, 'Config::IniFiles', (-file => $config_file);

our $log = VUser::Log->new(\%cfg, 'vsoapd/wsdl');

$log->log(LOG_DEBUG, "Config loaded from $config_file");

if (not $debug) {
    $DEBUG = VUser::ExtLib::strip_ws($cfg{'vuser'}{'debug'}) || 0;
    $DEBUG = VUser::ExtLib::check_bool($DEBUG) unless $DEBUG =~ /^\d+$/;
    $debug = $DEBUG;
}

my $eh = new VUser::ExtHandler (\%cfg);

## Build giant data structure first.
my %event_tree = ();

@keywords = $eh->get_keywords() unless @keywords;

# Skip a few special keywords.
foreach my $key (@keywords) {
    if ($key eq 'config'
        or $key eq 'help'
        or $key eq 'man'
        or $key eq 'version'
        or not $eh->is_keyword($key)
        ){ 
        next;
    }
   
    $event_tree{$key} = {descr => $eh->get_description($key),
                                        actions => {}}; 

    my @actions = $eh->get_actions($key);
    foreach my $act (@actions) {
        $event_tree{$key}{actions}{$act} = {descr => $eh->get_description($key, $act),
                                            opts => {}};
                                                                 
        my @opts = $eh->get_options ($key, $act);
        foreach my $opt (@opts) {
            my @meta = $eh->get_meta($key, $opt);
            $event_tree{$key}{actions}{$act}{opts}{$opt}
                = { descr => $eh->get_description($key, $act, $opt),
                    required => $eh->is_required($key, $act, $opt),
                    type => $meta[0]->type()
                    };
        }
    }
}

## Write the WSDL
print <<'HEAD';
<?xml version="1.0"?>
<wsdl:definitions name="VUser"
    targetNamespace="urn:/VUser"
    xmlns:tns="urn:/VUser"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:enc="http://schemas.xmlsoap.org/soap/encoding/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">
    
 <wsdl:types>
  <xsd:schema targetNamespace="urn:/VUser">
   <xsd:complexType name="ColumnArray">
    <xsd:complexContent>
     <xsd:restriction base="enc:Array">
      <xsd:attribute ref="enc:arrayType" wsdl:arrayType="xsd:string[]" />
     </xsd:restriction>
    </xsd:complexContent>
   </xsd:complexType>
   <xsd:complexType name="TypeArray">
    <xsd:complexContent>
     <xsd:restriction base="enc:Array">
      <xsd:attribute ref="enc:arrayType" wsdl:arrayType="xsd:string[]" />
     </xsd:restriction>
    </xsd:complexContent>
   </xsd:complexType>
   <xsd:complexType name="ValueArray">
    <xsd:complexContent>
     <xsd:restriction base="enc:Array">
      <xsd:attribute ref="enc:arrayType" wsdl:arrayType="xsd:string[]" />
     </xsd:restriction>
    </xsd:complexContent>
   </xsd:complexType>
   <xsd:complexType name="DataArray">
    <xsd:complexContent>
     <xsd:restriction base="enc:Array">
      <xsd:attribute ref="enc:arrayType" wsdl:arrayType="tns:ValueArray" />
     </xsd:restriction>
    </xsd:complexContent>
   </xsd:complexType>
   <xsd:complexType name="ResultSet">
    <xsd:all>
     <xsd:element name="columns" type="tns:ColumnArray" minOccurs="1" maxOccurs="1" />
     <xsd:element name="types" type="tns:TypeArray" minOccurs="1" maxOccurs="1" />
     <xsd:element name="values" type="tns:DataArray" minOccurs="1" maxOccurs="1" />
    </xsd:all>
   </xsd:complexType>
   <xsd:complexType name="Record">
    <xsd:complexContent>
     <xsd:restriction base="enc:Array">
      <xsd:attribute ref="enc:arrayType" wsdl:arrayType="tns:ResultSet" />
     </xsd:restriction>
    </xsd:complexContent>
   </xsd:complexType>
   <xsd:complexType name="RecordArray">
    <xsd:complexContent>
     <xsd:restriction base="enc:Array">
      <xsd:attribute ref="enc:arrayType" wsdl:arrayType="tns:Record" />
     </xsd:restriction>
    </xsd:complexContent>
   </xsd:complexType>
   <xsd:complexType name="StringArray">
    <xsd:complexContent>
     <xsd:restriction base="enc:Array">
      <xsd:attribute ref="enc:arrayType" wsdl:arrayType="xsd:string[]" />
     </xsd:restriction>
    </xsd:complexContent>
   </xsd:complexType>
  </xsd:schema>
 </wsdl:types>
   
HEAD

## Now for the <messages>

print <<'MSGS';
 <wsdl:message name="loginRequest">
  <wsdl:part name="username" type="xsd:string" />
  <wsdl:part name="password" type="xsd:string" />
 </wsdl:message>

 <wsdl:message name="loginResponse">
  <wsdl:part name="authinfo" type="xsd:string" />
 </wsdl:message>

 <wsdl:message name="get_keywordsRequest" >
  <wsdl:part name="authinfo" type="xsd:string" />
 </wsdl:message>

 <wsdl:message name="get_keywordsResponse">
  <wsdl:part name="keywords" type="tns:StringArray" />
 </wsdl:message>
 
 <wsdl:message name="get_actionsRequest" >
  <wsdl:part name="authinfo" type="xsd:string" />
  <wsdl:part name="keyword" type="xsd:string" />
 </wsdl:message>
 
 <wsdl:message name="get_actionsResponse">
  <wsdl:part name="actions" type="tns:StringArray" />
 </wsdl:message>
 
 <wsdl:message name="get_optionsRequest" >
  <wsdl:part name="authinfo" type="xsd:string" />
  <wsdl:part name="keyword" type="xsd:string" />
  <wsdl:part name="action" type="xsd:string" />
 </wsdl:message>

 <wsdl:message name="get_optionsResponse">
  <wsdl:part name="options" type="tns:StringArray" />
 </wsdl:message>
 
 <wsdl:message name="ResultsResponse">
  <wsdl:part name="results" type="tns:RecordArray" />
 </wsdl:message>
MSGS

foreach my $key (sort keys %event_tree) {
    foreach my $act (sort keys %{$event_tree{$key}{actions}}) {
        printf(" <wsdl:message name=\"%s_%sRequest\">\n", $key, $act);
        print "  <wsdl:part name=\"authinfo\" type=\"xsd:string\" />\n";
        foreach my $opt (sort keys %{$event_tree{$key}{actions}{$act}{opts}}) {
            my $wsdl_type = 'xsd:string';
            # Build switch to map VUser::Meta types to WSDL types
            printf("  <wsdl:part name=\"%s\" type=\"%s\">\n", $opt, $wsdl_type);
            printf("   <wsdl:documentation>%s</wsdl:documentation>\n",
                   $event_tree{$key}{actions}{$act}{opts}{$opt}{descr});
            print("  </wsdl:part>\n");            
        }
        print " </wsdl:message>\n";
        
        printf(" <wsdl:message name=\"%s_%sResponse\">\n", $key, $act);
        print "  <wsdl:part name=\"results\" type=\"tns:RecordArray\" />\n";
        print " </wsdl:message>\n";
    }
}

## <portType>
# default port that included login and get_* operations
print <<'PORT';
 <wsdl:portType name="DefaultPort">
  <wsdl:documentation>
   login() returns an authentication ticket that is passed in the headers
   to the other operations.
  </wsdl:documentation>
  <wsdl:operation name="login">
   <wsdl:input message="tns:loginRequest" />
   <wsdl:output message="tns:loginResponse" />
  </wsdl:operation>
  <wsdl:operation name="get_keywords">
   <wsdl:input message="tns:get_keywordsRequest" />
   <wsdl:output message="tns:get_keywordsResponse" />
  </wsdl:operation>
  <wsdl:operation name="get_actions">
   <wsdl:input message="tns:get_actionsRequest" />
   <wsdl:output message="tns:get_actionsResponse" />
  </wsdl:operation>
  <wsdl:operation name="get_options">
   <wsdl:input message="tns:get_optionsRequest" />
   <wsdl:output message="tns:get_optionsResponse" />
  </wsdl:operation>
 </wsdl:portType>
PORT

foreach my $key (sort keys %event_tree) {
    my $uc_key = ucfirst $key;
    # Documentation? keyword description
    printf(" <wsdl:portType name=\"%sPort\">\n", $uc_key);
    printf("  <wsdl:documentation>%s</wsdl:documentation>\n", $event_tree{$key}{descr});
        
    foreach my $act (sort keys %{$event_tree{$key}{actions}}) {
        my $uc_act = ucfirst($act);
        # Documentation? action description
        printf ("  <wsdl:operation name=\"%s_%s\">\n", $key, $act);
        printf("   <wsdl:documentation>%s</wsdl:documentation>\n",
               $event_tree{$key}{actions}{$act}{descr});
        printf ("   <wsdl:input message=\"tns:%s_%sRequest\" />\n", $key, $act);
        printf ("   <wsdl:output message=\"tns:%s_%sResponse\" />\n", $key, $act);
        #printf ("   <wsdl:output message=\"tns:ResultsResponse\" />\n");
        print "  </wsdl:operation>\n";
    }
    
    print(" </wsdl:portType>\n");
}

## <binding>
print <<'BINDING';
 <wsdl:binding name="DefaultSOAP" type="tns:DefaultPort">
  <soap:binding style="rpc"
    transport="http://schemas.xmlsoap.org/soap/http" />
  <wsdl:operation name="login">
   <soap:operation soapAction="urn:/VUser#login" />
   <wsdl:input>
    <soap:body use="encoded" parts="username password"
      namespace="urn:/VUser"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
   </wsdl:input>
   <wsdl:output>
    <soap:body use="encoded" namespace="urn:/VUser"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
   </wsdl:output>
  </wsdl:operation>
  <wsdl:operation name="get_keywords">
   <soap:operation soapAction="urn:/VUser#get_keywords" />
   <wsdl:input>
    <soap:body use="encoded"
      namespace="urn:/VUser"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
    <soap:header use="encoded" part="authinfo"
      namespace="urn:/VUser"
      message="tns:get_keywordsRequest" wsdl:required="1"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
   </wsdl:input>
   <wsdl:output>
    <soap:body use="encoded" namespace="urn:/VUser"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
   </wsdl:output>
  </wsdl:operation>
  <wsdl:operation name="get_actions">
   <soap:operation soapAction="urn:/VUser#get_actions" />
   <wsdl:input>
    <soap:body use="encoded" part="keyword"
      namespace="urn:/VUser"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
    <soap:header use="encoded" part="authinfo"
      namespace="urn:/VUser"
      message="tns:get_actionsRequest" wsdl:required="1"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
   </wsdl:input>
   <wsdl:output>
    <soap:body use="encoded" namespace="urn:/VUser"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
   </wsdl:output>
  </wsdl:operation>
  <wsdl:operation name="get_options">
   <soap:operation soapAction="urn:/VUser#get_options" />
   <wsdl:input>
    <soap:body use="encoded" parts="keyword action"
      namespace="urn:/VUser"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
    <soap:header use="encoded" part="authinfo"
      namespace="urn:/VUser"
      message="tns:get_optionsRequest" wsdl:required="1"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
   </wsdl:input>
   <wsdl:output>
    <soap:body use="encoded" namespace="urn:/VUser"
      encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" />
   </wsdl:output>
  </wsdl:operation>
 </wsdl:binding>
BINDING

foreach my $key (sort keys %event_tree) {
    my $uc_key = ucfirst($key);
    
    printf (" <wsdl:binding name=\"%sSOAP\" type=\"tns:%sPort\">\n", $uc_key, $uc_key);
    # Test here for transport
    print "  <soap:binding style=\"rpc\" transport=\"http://schemas.xmlsoap.org/soap/http\" />\n";
    
    foreach my $act (sort keys %{ $event_tree{$key}{actions} }) {
        my $uc_act = ucfirst($act);
        # Documentation? action description?
        printf("  <wsdl:operation name=\"%s_%s\">\n", $key, $act);
        printf( "   <soap:operation soapAction=\"urn:/VUser#%s_%s\" />\n", $key, $act);
        print "   <wsdl:input>\n";
        printf("    <soap:body use=\"encoded\"");
        if (keys %{ $event_tree{$key}{actions}{$act}{opts} }) {
            printf(" parts=\"%s\"",
                join " ", sort keys %{ $event_tree{$key}{actions}{$act}{opts} });
        }
        print " namespace=\"urn:/VUser\" encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" />\n";
        print "    <soap:header use=\"encoded\" part=\"authinfo\"";
        #printf (" message=\"tns:%s%sRequest\" wsdl:required=\"1\"", $uc_key, $uc_act);
        printf (" message=\"tns:%s_%sRequest\" wsdl:required=\"1\"", $key, $act);
        print " namespace=\"urn:/VUser\" encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" />\n";
        print "   </wsdl:input>\n";
        print "   <wsdl:output>\n";
        print "    <soap:body use=\"encoded\" namespace=\"urn:/VUser\"";
        print " encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" />\n";
        print "   </wsdl:output>\n";
        print "  </wsdl:operation>\n";
    }
    print " </wsdl:binding>\n";
}

## <service>
print <<'SERVICE';
 <wsdl:service name="VUser">
  <wsdl:port name="DefaultPort" binding="tns:DefaultSOAP">
SERVICE
# Location set in vuser.conf
my $location = strip_ws($cfg{$c_sec}{location});
$location = 'http://localhost:8000' unless $location;
printf ("   <soap:address location=\"%s\" />\n", $location);
print "  </wsdl:port>\n";

foreach my $key (sort keys %event_tree) {
    my $uc_key = ucfirst($key);
    printf ("  <wsdl:port name=\"%sPort\" binding=\"tns:%sSOAP\">\n", $uc_key, $uc_key);
    printf ("   <soap:address location=\"%s\" />\n", $location);
    print("  </wsdl:port>\n");
}
print " </wsdl:service>\n";
print "</wsdl:definitions>\n";

1;

__END__

=head1 NAME

gen-wsdl.pl - Generate WSDL file(s) that match the services offered by vsoapd

=head1 SYNOPSIS

 get-wsdl.pl [--config=/path/to/vuser.conf] [--keywords=key1[,key2]]

=head1 DESCRIPTION

Generate WSDL files that match the services offered by vsoapd.

=head1 CONFIGURATION

=head1 BUGS

Wildcard actions cannot be easily translated into a WSDL.

All result set values are strings. This is not really a bug but a problem
translating the flexibilty of Perl into a static format such as WSDL.
The types are passed as part of the result set sent back to the SOAP client.
It is up to the client to do translation at that point. 

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of vsoapd.
 
 vsoapd is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vsoapd is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vsoapd; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
