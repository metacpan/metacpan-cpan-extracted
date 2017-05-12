# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-FXN.t'

#########################


use Test::More tests => 3;
BEGIN { use_ok('XML::FXN') };

#########################

use strict;
use warnings;

my $xml_document = <<EOXML;
   <?xml version="1.0" standalone="yes"?>
   <!DOCTYPE >
  <!--   This is an example from PSI <
<< >>>config file -->
<accounts default='default'>
  <default>
    <item id="123456">
    <name>
       flangie
    </name>
    <description>
       Brand new technology to accompany our <item-link id="654321">callioscim</item-link> 
       for those really tough jobs.
    </description>
</item>

    <user>
      <name>fbHNkg==</name>
      <password>bb0GsZoM</password>
      <resource>Just another jabber client</resource>
      <priority>0</priority>
    </user>
    <server>
      <host>wodent</host>
      <ip />
      <byip>false</byip>
      <port>5322</port>
      <usessl>false</usessl>
      <newaccount>false</newaccount>
      <savepassword>true</savepassword>
      <plaintext>false</plaintext>
      <autologin>true</autologin>
      <local>false</local>
      <keyfile />
    </server>    
  </default>
</accounts>
EOXML

my $fxn_document = <<EOFXN;
   <?xml version="1.0" standalone="yes"?>
   <!DOCTYPE >
  <!--   This is an example from PSI <
<< >>>config file -->
accounts default='default'<
  default<
    item id="123456"<
    name<
       flangie
    >
    description<
       Brand new technology to accompany our  item-link id="654321"<callioscim> 
       for those really tough jobs.
    >
>

    user<
      name<fbHNkg==>
      password<bb0GsZoM>
      resource<Just another jabber client>
      priority<0>
    >
    server<
      host<wodent>
      ip <>
      byip<false>
      port<5322>
      usessl<false>
      newaccount<false>
      savepassword<true>
      plaintext<false>
      autologin<true>
      local<false>
      keyfile <>
    >    
  >
>
EOFXN

is( xml2fxn( $xml_document ), $fxn_document,
 'Transformation from XML to FXN;' );
is( fxn2xml( $fxn_document ), $xml_document,
 'Transformation from FXN to XML.' )



