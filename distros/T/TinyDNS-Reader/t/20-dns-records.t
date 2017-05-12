#!/usr/bin/perl -Iblib/lib/
#
#  Test we can parse at least some records successfully.
#
# Steve
# --
#

use strict;
use warnings;


use Test::More qw! no_plan !;

BEGIN {use_ok("TinyDNS::Reader")}
require_ok("TinyDNS::Reader");

BEGIN {use_ok("TinyDNS::Record")}
require_ok("TinyDNS::Record");



#
#  Parse the given text and return the records.
#
sub getObj
{
    my ($txt) = (@_);

    # create
    my $o = TinyDNS::Reader->new( text => $txt );
    isa_ok( $o, "TinyDNS::Reader" );

    # parse
    my $out = $o->parse();
    ok( $out, "Parsing resulted in a non-empty value" );
    is( ref($out), "ARRAY", "Which has the right type" );


    my @ret = @$out;
    return (@ret);
}



#
# Traditional MX.
#
my @all = getObj("\@edinburgh.io:mail.steve.org.uk:15");
is( scalar(@all),         1,                      "One record" );
is( $all[0]->{ 'type' },  "MX",                   "Got the right type" );
is( $all[0]->{ 'name' },  "edinburgh.io",         "Got the right name" );
is( $all[0]->{ 'value' }, "15 mail.steve.org.uk", "Got the right value" );
is( $all[0]->{ 'ttl' },   "300", "Got the default TTL" );


#
#  Traditional MX record with trailing TTL too.
#
@all = getObj("\@example.com:mail.steve.org.uk:15:3600");
is( scalar(@all),         1,                      "One record" );
is( $all[0]->{ 'type' },  "MX",                   "Got the right type" );
is( $all[0]->{ 'name' },  "example.com",          "Got the right name" );
is( $all[0]->{ 'value' }, "15 mail.steve.org.uk", "Got the right value" );
is( $all[0]->{ 'ttl' }, "3600", "Got the correct TTL" );


#
#  NS record
#
@all = getObj("&sub.edinburgh.io::ns.example.com:300");
is( scalar(@all),         1,                  "One record" );
is( $all[0]->{ 'type' },  "NS",               "Got the right type" );
is( $all[0]->{ 'name' },  "sub.edinburgh.io", "Got the right name" );
is( $all[0]->{ 'value' }, "ns.example.com",   "Got the right value" );


#
#  TXT
#
@all = getObj("Tedinburgh.io:\"v=spf1 mx a ptr ip4:1.2.3.4 ?all\":300\n");
is( scalar(@all), 1, "One record" );

is( $all[0]->{ 'type' }, "TXT",          "Got the right type" );
is( $all[0]->{ 'name' }, "edinburgh.io", "Got the right name" );
is( $all[0]->{ 'value' },
    "\"v=spf1 mx a ptr ip4:1.2.3.4 ?all\"",
    "Got the right value" );




#
#  A
#
@all = getObj("+edinburgh.io:1.2.3.4:300");
is( scalar(@all), 1, "One record" );

is( $all[0]->{ 'type' },  "A",            "Got the right type" );
is( $all[0]->{ 'name' },  "edinburgh.io", "Got the right name" );
is( $all[0]->{ 'value' }, "1.2.3.4",      "Got the right value" );




#
#  AAAAA
#
@all = getObj("6www.edinburgh.io:200141c8010b01030000000000000010:300");
is( scalar(@all), 1, "One record" );

is( $all[0]->{ 'type' }, "AAAA",             "Got the right type" );
is( $all[0]->{ 'name' }, "www.edinburgh.io", "Got the right name" );
is( $all[0]->{ 'value' },
    "2001:41c8:010b:0103:0000:0000:0000:0010",
    "Got the right value" );



#
#  Finally we want to ensure that the random-records we have are valid.
#
foreach my $line (<DATA>)
{
    chomp($line);
    next if ( !length($line) );
    next if ( $line =~ /^#/ );

    my $x = TinyDNS::Record->new($line);
    ok( $x, "Parsed line: $line" );
    is( $x->valid(), 1, "Valid" );
}


#
#  Random assortment.
#
__DATA__

#
#  MX record and matching SMTP host.
#
#
@steve.org.uk::mail.steve.org.uk:15
+mail.steve.org.uk:80.68.84.102:300
6mail.steve.org.uk:200141c8010b01020000000000000010:300
+webmail.steve.org.uk:80.68.84.104:300


#
#  SSH is a CNAME.
#
Cssh.steve.org.uk:mail.steve.org.uk:300

#
#  IPv4 + IPv6 hosts
#
+ipv4.steve.org.uk:80.68.84.103:300
6ipv6.steve.org.uk:200141c8010b01030000000000000010:300

#
#  All other hosts are both IPv4 + IPv6
#
6blog.steve.org.uk:200141c8010b01030000000000000010:300
+blog.steve.org.uk:80.68.84.103:300

6openid.steve.org.uk:200141c8010b01030000000000000010:300
+openid.steve.org.uk:80.68.84.103:300

6packages.steve.org.uk:200141c8010b01030000000000000010:300
+packages.steve.org.uk:80.68.84.103:300

6picshare.steve.org.uk:200141c8010b01030000000000000010:300
+picshare.steve.org.uk:80.68.84.103:300

# for redirecting registered/unusued domains
6taken.steve.org.uk:200141c8010b01030000000000000010:300
+taken.steve.org.uk:80.68.84.103:300

6repository.steve.org.uk:200141c8010b01020000000000000010:300
+repository.steve.org.uk:80.68.84.102:300

#
# wildcard subdomains for *.repository.steve.org.uk
#
6*.repository.steve.org.uk:200141c8010b01020000000000000010:300
+*.repository.steve.org.uk:80.68.84.102:300

6static.steve.org.uk:200141c8010b01030000000000000010:300
+static.steve.org.uk:80.68.84.103:300

6stats.steve.org.uk:200141c8010b01030000000000000010:300
+stats.steve.org.uk:80.68.84.103:300

+todo.steve.org.uk:80.68.84.103:300
6todo.steve.org.uk:200141c8010b01030000000000000010:300

6steve.org.uk:200141c8010b01030000000000000010:300
+steve.org.uk:80.68.84.103:300

6www.steve.org.uk:200141c8010b01030000000000000010:300
+www.steve.org.uk:80.68.84.103:300

# Git repos
+git.steve.org.uk:80.68.84.108:300
6git.steve.org.uk:200141c8010b01080000000000000010:300

# chat server + port-settings.
+chat.steve.org.uk:80.68.84.109:300

# package-builder
+builder.steve.org.uk:80.68.84.105:300
6builder.steve.org.uk:200141c8010b01050000000000000010:300

#
# Docker
#
+docker.steve.org.uk:80.68.84.107:300
6docker.steve.org.uk:200141c8010b01070000000000000010:300

# guest
+graphite.docker.steve.org.uk:80.68.84.107:300
6graphite.docker.steve.org.uk:200141c8010b01070000000000000010:300


#
#  The general form of the input is ":" deliminated records:
#
#   TYPE : NAME : VALUE : TTL
#
#  Where type is:
#
#   @ for MX.
#   + for A.
#   6 for AAAA.
#   C for CNAME.
#   T for TXT.


#
#  MX record - note we have priority not TTL here.
#
@edinburgh.io:mail.steve.org.uk:15

#
#  IPv4 records.
#
+edinburgh.io:80.68.84.103:300
+www.edinburgh.io:80.68.84.103:300

#
#  IPv6 records - note lack of ":" in the address.
#
6edinburgh.io:200141c8010b01030000000000000010:300
6www.edinburgh.io:200141c8010b01030000000000000010:300


#
#  A TXT record - NOTE That the value must be quoted.
#
Tedinburgh.io:"v=spf1 mx a ptr ip4:1.2.3.4 ?all":300
Tsub.edinburgh.io:"v=spf1 mx a ptr ip4:1.2.3.4 ?all"


#
# This is a CNAME
#
Cexample.edinburgh.io:example.com:300

#
# Ptr record
#
^46.85.68.80.in-addr.arpa:ssh.steve.org.uk
^47.85.68.80.in-addr.arpa:mail.steve.org.uk:300

&sub.steve.org.uk::ns1.example.com:300
