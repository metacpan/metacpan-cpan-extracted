#####
#
# $Id: diagnose_bgp.pl,v 1.16 2003/03/02 11:12:04 dsw Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001, 2003, Juniper Networks, Inc.  
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
# diagnose_bgp.pl
#
#    description:
#
#        Parse through the output of 'show bgp summary' and
#	 display key information on the unestablished peers.
#
#####
use JUNOS::Device;
use JUNOS::Trace;
use XML::DOM;
use strict;
use Getopt::Std;
use Term::ReadKey;
use File::Basename;

use constant OUTPUT_FORMAT => "%-20s%-8s%-8s%-11s%-14s%s\n";
use constant OUTPUT_TITLE => "\n========================= BGP PROBLEM SUMMARY =========================\n\n";
use constant OUTPUT_ENDING => "\n=======================================================================\n\n";

#
# Set AUTOFLUSH to true
#
$| = 1;

#
# Make jnx a global variable
#
my $jnx;

# Format the HTML output using XSLT
sub format_by_xslt
{
    my ($xslfile, $xmlfile, $outfile)  = @_;

    print "Transforming $xmlfile with $xslfile...\n" if $outfile;
    my $command = "xsltproc $xslfile $xmlfile";
    $command .= "> $outfile" if $outfile;
    system($command);
    print "Done\n" if $outfile;
    print "See $outfile\n" if $outfile;
}

# send a query
sub send_query
{
    my $device = shift;
    my $query = shift;
    my $href_queryargs = shift;
    my $res;
    unless ( ref $href_queryargs ) {
        $res = $device->$query();
    } else {
        my %queryargs = %$href_queryargs;
	# sending a request, show progress
        $res = $device->$query(%queryargs);
    }

    unless ( ref $res ) {
        print STDERR "ERROR: Failed to execute query '$query'\n";
        return 0;
    }

    #
    # PROCESS THE RESPONSE
    # Check and see if there were any errors in executing the command.
    # If all is well, analyze the response.
    #

    my $err = $res->getFirstError();
    if ($err) {
        print STDERR "ERROR: ", $err->{message}, "\n";
        return 0;
    }

    return $res;
}

# get element value
sub get_element_value
{
    my $doc = shift;
    my $tag = shift;

    my $nodes = $doc->getElementsByTagName($tag);
    if ( ! $nodes ) {
        print "can't get nodes for $tag\n";
        return;
    }

    my $node = $nodes->item(0);
    if ( ! $node ) {
        print "can't get node for $tag\n";
        return;
    }

    my $elem = $node->getFirstChild(); #these nodes only have a text child
    if ( ! $elem ) {
        print "can't get elem for $tag\n";
        return;
    }

    my $value = $elem->getData;
    if ( ! $value ) {
        print "can't get data for $tag\n";
        return;
    }
    $value =~ s/\n//g;

    return $value;
}

# parse through the bgp summary for unestablished peers
sub analyze_bgp_summary
{
    my $device = shift;
    my $hostname = shift;
    my @table;

    #
    # SEND THE QUERY
    # set the query to 'get_bgp_neighbor_information', see
    # lib/JUNOS/jkernal_methods.pl and lib/JUNOS/jroute_methods.pl
    # for a list of valid queries.
    #
    # This query gets the current information of all the BGP neighbors
    # of a specific router. It's equivalent to invoking 
    # 'show bgp neighbor' on the router's CLI.
    #

    my $query = "get_bgp_neighbor_information";
    my $res = send_query($device, $query);

    unless (ref $res) {
   	print STDERR "ERROR: $hostname: failed to execute command $query\n";
	return undef;
    }

    my $err = $res->getFirstError();
    if ($err) {
   	print STDERR "ERROR: $hostname: " . $err->{message} . "\n";
	return undef;
    }

    return $res;

}

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
  -x <xslfile>	XSL file.  Default: formatting using Perl.
  -o <outfile>	Output file for transformation using XSLT.  Default: xslfile.html.
  -d            Turn on debug, full blast.\n\n";

    die $usage;
}

#
# CHECK ARGUMENTS
# Make sure all the required arguments are entered and the optional
# ones are set to the appropriate defaults if not supplied by on
# the command line.
#

my %opt;
getopts('l:p:dm:x:o:h', \%opt) || output_usage();
output_usage() if $opt{h};

# Check whether trace should be turned on
JUNOS::Trace::init(1) if $opt{d};

my $hostname = shift || output_usage();

# Retrieve the access method, can only be telnet or ssh.
my $access = $opt{m} || "telnet";
use constant VALID_ACCESSES => "telnet|ssh|clear-text|ssl";
output_usage() unless (VALID_ACCESSES =~ /$access/);

# Check whether login name has been entered.  Otherwise prompt for it
my $login = "";
if ($opt{l}) {
    $login = $opt{l};
} else {
    print "login: ";
    $login = ReadLine 0;
    chomp $login;
}

# Check whether password has been entered.  Otherwise prompt for it
my $password = "";
if ($opt{p}) {
    $password = $opt{p};
} else {
    print "password: ";
    ReadMode 'noecho';
    $password = ReadLine 0;
    chomp $password;
    ReadMode 'normal';
    print "\n";
}

# Retrieve the XSLT file, default is parsed by perl
my $xslfile = $opt{x} || "xsl/text.xsl";
if ($xslfile && ! -f $xslfile) {
    die "ERROR: XSLT file $xslfile does not exist";
}

# Get the name of the output file
my $outfile = $opt{o};

# Retrieve command line arguments
my %deviceinfo = (
        access => $access,
        login => $login,
        password => $password,
        hostname => $hostname,
    );

#
# CONNECT TO the JUNOScript server
# Create a device object that contains all necessary information to
# connect to the JUNOScript server at a specific router.
#

$jnx = new JUNOS::Device(%deviceinfo);
unless ( ref $jnx ) {
    die "ERROR: $deviceinfo{hostname}: failed to connect.\n";
}

#
# RETRIEVE BGP SUMMARY
# Retrieve the BGP summary and process the result.  Display information
# on the unestablished peers.
#
my $res = analyze_bgp_summary($jnx, $deviceinfo{hostname});
if ($res) {
    # print <diagnose-bgp> to xml file
    my $xmlfile = "$hostname.xml";
    $res->printToFile($xmlfile);

    my $nm = $res->translateXSLtoRelease('xmlns:lc', $xslfile, "$xslfile.tmp");
    if ($nm) {
        format_by_xslt($nm, $xmlfile, $outfile);
    } else {
        print STDERR "ERROR: Invalid XSL File $xslfile\n";
    }
}

# always close the connection
$jnx->request_end_session();
$jnx->disconnect();
