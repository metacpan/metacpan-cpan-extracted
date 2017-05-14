#####
#
# $Id: load_configuration.pl,v 1.18 2003/03/02 11:12:06 dsw Exp $
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
# load_configuration.pl
#
#    description:
#
#        load the configuration from an xml file and report the result.
#
#####
use JUNOS::Device;
use JUNOS::Trace;
use Getopt::Std;
use Term::ReadKey;

#
# Define the constants used in this example
#
use constant REPORT_SUCCESS => 1;
use constant REPORT_FAILURE => 0;
use constant STATE_CONNECTED => 1;
use constant STATE_LOCKED => 2;
use constant STATE_CONFIG_LOADED => 3;


# print the usage of this script
sub output_usage
{
    my $usage = "Usage: $0 [options] <request> <target>

Where:

  <request>  name of a specific xml file containing the configuration
             in xml or text.  By default, the content of this file is
             xml, for example:
                 <configuration>
                     <system>
                         <host-name>my-host-name</host-name>
                     </system>
                 </configuration>
             If the -t option is used, the content of this file should
             be in text within the configuration-text element, for example:
                 <configuration-text>
                     system {
                         host-name my-host-name;
                     }
                 </configuration-text>

  <target>   The hostname of the target router.

Options:

  -l <login>    A login name accepted by the target router.
  -p <password> The password for the login name.
  -m <access>	Access method.  It can be clear-text, ssl, ssh or telnet.  Default: telnet.
  -t            Loading a text configuration instead of xml.  See description of <request>.
  -a            Specify which load action should be used, 'merge', 'replace' or 'override'.
                The default is 'merge'.
  -d            turn on debug, full blast.\n\n";

    die $usage;
}

# grace_shutdown
# To gracefully shutdown.  Recognized 3 states:  1 connected, 2 locked, 
# 3 config_loaded
# Put eval around each step to make sure the next step is performed no
# matter what.
sub graceful_shutdown
{
    my ($jnx, $req, $state, $success) = @_;

    if ($state >= STATE_CONFIG_LOADED) {
        print "Rolling back configuration ...\n";
	eval {
            $jnx->load_configuration(rollback => 0);
	};
    }

    if ($state >= STATE_LOCKED) {
        print "Unlocking configuration database ...\n";
	eval {
            $jnx->unlock_configuration();
	};
    }

    if ($state >= STATE_CONNECTED) {
        print "Disconnecting from the router ...\n";
	eval {
	    $jnx->request_end_session();
            $jnx->disconnect();
	}
    }

    if ($success) {
        die "REQUEST $req SUCCEEDED\n";
    } else {
        die "REQUEST $req FAILED\n";
    }
}

#
# escape special symbols in text
#
my %escape_symbols = (
                qq(")           => '&quot;',
                qq(>)           => '&gt;',
                qq(<)           => '&lt;',
                qq(')           => '&apos;',
                qq(&)           => '&amp;'
                );

# Create regex of these
my $char_class = join ("|", map { "($_)" } keys %escape_symbols);

sub get_escaped_text
{
    my $input_file = shift;
    my $input_string = "";

    open(FH, $input_file) or return undef;

    while(<FH>) {
	my $line = $_;
        $line =~ s/<configuration-text>//g;
        $line =~ s/<\/configuration-text>//g;
	$line =~ s/($char_class)/$escape_symbols{$1}/ge;
	$input_string .= $line;
    }

    return "<configuration-text>$input_string</configuration-text>";
}

#
# Read XML from a file, stripping the <?xml version=...?> tag if necessary
#
sub read_xml_file
{
    my $input_file = shift;
    my $input_string = "";

    open(FH, $input_file) || return;

    while(<FH>) {
	next if /<\?xml.*\?>/;
	$input_string .= $_;
    }

    close(FH);

    return $input_string;
}

#
# Set AUTOFLUSH to true
#
$| = 1;

# check arguments
my %opt;
getopts('l:p:dm:hta:', \%opt) || output_usage();
output_usage() if $opt{h};

# Check whether trace should be turned on
JUNOS::Trace::init(1) if $opt{d};

# The default configuration format is xml unless -t is specified
my $config_format = "xml";
$config_format = "text" if $opt{t};

# The default action for load_configuration is 'merge'
my $load_action = "merge";
$load_action = $opt{a} if $opt{a};
use constant VALID_ACTIONS => "merge|replace|override";
output_usage() unless (VALID_ACTIONS =~ /$load_action/);

# Retrieve command line arguments
my $xmlfile = shift || output_usage();

# Retrieve host name
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

my %deviceinfo = (
        access => $access,
        login => $login,
        password => $password,
        hostname => $hostname,
    );

# Initialize the XML Parser
my $parser = new XML::DOM::Parser;

# connect TO the JUNOScript server
my $jnx = new JUNOS::Device(%deviceinfo);
unless ( ref $jnx ) {
    die "ERROR: $deviceinfo{hostname}: failed to connect.\n";
}

#
# Lock the configuration database before making any changes
# 
print "Locking configuration database ...\n";
my $res = $jnx->lock_configuration();
my $err = $res->getFirstError();
if ($err) {
    print "ERROR: $deviceinfo{hostname}: failed to lock configuration.  Reason: $err->{message}.\n";
    graceful_shutdown($jnx, $xmlfile, STATE_CONNECTED, REPORT_FAILURE);
}

#
# Load the configuration
# 
print "Loading configuration from $xmlfile ...\n";
if (! -f $xmlfile) {
    print "ERROR: Cannot load configuration in $xmlfile\n";
    graceful_shutdown($jnx, $xmlfile, STATE_LOCKED, REPORT_FAILURE);
} 
my $doc;
if ($opt{t}) {
    my $xmlstring = get_escaped_text($xmlfile);
    $doc = $parser->parsestring($xmlstring) if $xmlstring;
} else {
    my $xmlstring = read_xml_file($xmlfile);
    $doc = $parser->parsestring($xmlstring) if $xmlstring;
}
unless ( ref $doc ) {
    print "ERROR: Cannot parse $xmlfile, check to make sure the XML data is well-formed\n";
    graceful_shutdown($jnx, $xmlfile, STATE_LOCKED, REPORT_FAILURE);
}

#
# Put the load_configuration in an eval block to make sure if the rpc-reply
# has any parsing errors, the grace_shutdown will still take place.  Do
# not leave the database in an exclusive lock state.
#
eval {
    $res = $jnx->load_configuration(
	    format => $config_format, 
	    action => $load_action,
	    configuration => $doc);
};
if ($@) {
    print "ERROR: Failed to load the configuration from $xmlfile.   Reason: $@\n";
    graceful_shutdown($jnx, $xmlfile, STATE_CONFIG_LOADED, REPORT_FAILURE);
    exit(1);
} 

unless ( ref $res ) {
    print "ERROR: Failed to load the configuration from $xmlfile\n";
    graceful_shutdown($jnx, $xmlfile, STATE_LOCKED, REPORT_FAILURE);
}

$err = $res->getFirstError();
if ($err) {
    print "ERROR: Failed to load the configuration.  Reason: $err->{message}\n";
    graceful_shutdown($jnx, $xmlfile, STATE_CONFIG_LOADED, REPORT_FAILURE);
}

#
# Commit the change
#
print "Commiting configuration from $xmlfile ...\n";
$res = $jnx->commit_configuration();
$err = $res->getFirstError();
if ($err) {
    print "ERROR: Failed to commit configuration.  Reason: $err->{message}.\n";
    graceful_shutdown($jnx, $xmlfile, STATE_CONFIG_LOADED, REPORT_FAILURE);
}

#
# Cleanup
#
graceful_shutdown($jnx, $xmlfile, STATE_LOCKED, REPORT_SUCCESS);
