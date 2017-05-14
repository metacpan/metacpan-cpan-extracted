#####
#
# $Id: get_chassis_inventory.pl,v 1.17 2003/03/02 11:12:05 dsw Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001-2003, Juniper Networks, Inc.  
# All rights reserved.  
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#####

#####
#
# get_chassis_inventory.pl
#
#    description:
#
#        Creates a hardware inventory and display the inventory
#        using XSLT.
#
#####
use JUNOS::Device;
use JUNOS::Trace;
use strict;
use Getopt::Std;
use Term::ReadKey;

# print the usage of this script
sub output_usage
{
    my $usage = "Usage: $0 [options] <target>

Where:

  <target>   The hostname of the target router.

Options:

  -l <login>    A login name accepted by the target router.
  -p <password> The password for the login name.
  -m <access>	Access method.  It can be clear-text, ssl, ssh or telnet.  Default: telnet.
  -x <format>   The name of the XSL file to display the response. 
                Default: xsl/chassis_inventory_csv.xsl
  -o <filename>	output is written to this file instead of standard output.
  -d            turn on debug, full blast.\n\n";

    die $usage;
}


#
# BORING STUFF!!!
# Gathering command line argument to prepare for the JUNOScript 
# request.
# This section of the code is doing the normal command line
# argument retrieval, you're not learning anything new here.
#

# check arguments
my %opt;
getopts('l:p:dx:m:o:h', \%opt) || output_usage();
output_usage() if $opt{h};

# Check whether trace should be turned on
JUNOS::Trace::init(1) if $opt{d};

my $hostname = shift || output_usage();

# Retrieve the access method, can only be telnet or ssh.
my $access = $opt{m} || "telnet";
use constant VALID_ACCESSES => "telnet|ssh|clear-text|ssl";
output_usage() unless (VALID_ACCESSES =~ /$access/);

# Retrieve the output format, can only be html, xml or csv.
my $xslfile = $opt{x} || "xsl/chassis_inventory_csv.xsl";

# Check whether login name has been entered.  Otherwise prompt for it
my $login = "";
if ($opt{l}) {
    $login = $opt{l};
} else {
    print STDERR "login: ";
    $login = ReadLine 0;
    chomp $login;
}

# Check whether password has been entered.  Otherwise prompt for it
my $password = "";
if ($opt{p}) {
    $password = $opt{p};
} else {
    print STDERR "password: ";
    ReadMode 'noecho';
    $password = ReadLine 0;
    chomp $password;
    ReadMode 'normal';
    print STDERR "\n";
}

my $outputfile = $opt{o} || "";
my %deviceinfo = (
        access => $access,
        login => $login,
        password => $password,
        hostname => $hostname,
    );

# Check to make sure the XSL exists
if (! -f $xslfile) {
    die "XSL file $xslfile does not exist.";
}

#
# INTERESTING BIT!!!
# This section of the code is the interesting part, showing you
# how simple it is to send the JUNOScript request, and display 
# the response using xsltproc.
#

# The query to access hardward inventory, same as doing the CLI
# command 'show chassis hardware'
my $query = "get_chassis_inventory";
my %queryargs = ( detail => 1 );

# connect TO the JUNOScript server
my $jnx = new JUNOS::Device(%deviceinfo);
unless ( ref $jnx ) {
    die "ERROR: $deviceinfo{hostname}: failed to connect.\n";
}

# send the command and receive a XML::DOM object
my $res = $jnx->$query( %queryargs );
unless ( ref $res ) {
    die "ERROR: $deviceinfo{hostname}: failed to execute command $query.\n";
}

# Check and see if there were any errors in executing the command.
# If all is well, output the response using XSLT.
my $err = $res->getFirstError();
if ($err) {
    print STDERR "ERROR: $deviceinfo{'hostname'} - ", $err->{message}, "\n";
} else {
    #
    # Now do the transformation using XSLT.
    # 
    my $xmlfile = "$deviceinfo{hostname}.xml";
    $res->printToFile($xmlfile);
    my $nm = $res->translateXSLtoRelease('xmlns:lc', $xslfile, "$xslfile.tmp");
    if ($nm) {
	print "Transforming $xmlfile with $xslfile...\n" if $outputfile;
	my $command = "xsltproc $nm $deviceinfo{hostname}.xml";
	$command .= "> $outputfile" if $outputfile;
        system($command);
	print "Done\n" if $outputfile;
	print "See $outputfile\n" if $outputfile;
    } else {
	print STDERR "ERROR: Invalid XSL File $xslfile\n";
    }
}

# always close the connection
$jnx->request_end_session();
$jnx->disconnect();
