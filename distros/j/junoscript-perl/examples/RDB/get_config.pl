#####
#
# $Id: get_config.pl,v 1.16 2003/07/09 19:36:04 trostler Exp $
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

my %escapes = ( 
		'&quot;'	=> qq("),
		'&gt;'		=> qq(>),
		'&lt;'		=> qq(<),
		'&apos;'	=> qq('),
		'&amp;'		=> qq(&)
		);

# Create regex of these
my $char_class = join ("|", map { "($_)" } keys %escapes);

#####
#
# get_config.pl
#
#    description:
#
#    Stores the current configuration to a file in XML format
#
#    This script will fail with an error if the configuration
#    is modified and not committed at the time this script is
#    run (except for comment annotations)
#
#####
use JUNOS::Device;
use JUNOS::Methods;
use Getopt::Std;
use Term::ReadKey;
use strict;

sub lock ( $$ );
sub unlock ( $$ );
sub getconfig ( $$$ );
sub outconfig( $$$$ );

# print the usage of this script
sub output_usage
{
    my $usage = "Usage: $0 [options] <request> <target(s)>

Where:

  <request>  name of directory to place XML configuration file
             Base path should not end in a '/'. Use \".\" for current directory.

  <target(s)>   The hostname(s) of the target router(s).

Options:

  -l <login>    A login name accepted by the target router.
  -p <password> The password for the login name.
  -m <access>	Access method.  It can be clear-text, ssl, ssh or telnet.  Default: telnet.
  -i            Run in interactive mode
  -t            Fetch configuration as text
  -d            turn on debug, full blast.\n\n";

    die $usage;
}


main: {
    # check arguments
    my(%opt,$login,$password);

    getopts('l:p:dm:hit', \%opt) || output_usage();
    output_usage() if $opt{h};

    # Check whether trace should be turned on
    JUNOS::Trace::init(1) if $opt{d};

    my $basepath = shift || output_usage;

    # just checking...
    my $host = shift || output_usage;
    unshift @ARGV, $host;

    # Retrieve command line arguments

    my $password = "";
    my $login = "";

    if (!$opt{i})
    {

    # set up the host structure with the command line arguments EXCEPT 
    #   for hostname
    # Check whether login name has been entered.  Otherwise prompt for it
    if ($opt{l}) {
        $login = $opt{l};
    } else {
        print STDERR "login: ";
        $login = ReadLine 0;
        chomp $login;
    }
    
    # Check whether password has been entered.  Otherwise prompt for it
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
    }

    my $access = $opt{m} || 'telnet';
    use constant VALID_ACCESSES => "telnet|ssh|clear-text|ssl";
    output_usage() unless (VALID_ACCESSES =~ /$access/);

    my %deviceinfo = (
            access => $access,
            login => $login,
            password => $password,
            'ssh-debug' => $opt{d},
            'ssh-interactive' => $opt{i}
        );

    while( my $hostname = shift @ARGV ) {
        $deviceinfo{'hostname'} = $hostname;

        # initialize junoscript
        my $jnx = new JUNOS::Device(%deviceinfo);
        unless ( ref $jnx ) {
            print "ERROR: for $hostname: Failed to create device\n";
            next;
        }

        # connect
        unless ( $jnx->connect() ) {
            print "ERROR: for $hostname: Failed to connect\n";
            next;
        }

        next unless lock( $hostname, $jnx );
        my $config = getconfig( $hostname, $jnx, $opt{t} );
        next unless unlock( $hostname, $jnx );

        # always close the connection
        $jnx->disconnect();

        outconfig( $basepath, $hostname, $config, $opt{t} );
    }

    exit(0);
}



sub lock ( $$ ) {
    my $hostname = shift;
    my $jnx = shift;

    # send the command
    my $res = $jnx->lock_configuration();
    unless ( ref $res ) {
        $jnx->disconnect();
        print "ERROR: Failed to lock configuration for $hostname\n";
    	return 0;
    }

    # check and see if there were any errors in executing the command
    my $err = $res->getFirstError();
    if ($err) {
        $jnx->disconnect();
        print "ERROR: for $hostname: " . $err->{message} . "\n";
        return 0;
    }
    return 1;
}


sub unlock ( $$ ) {
    my $hostname = shift;
    my $jnx = shift;

    # send the command
    my $res = $jnx->close_configuration();
    unless ( ref $res ) {
        $jnx->disconnect();
        print "ERROR: Failed to unlock configuration for $hostname\n";
    	return 0;
    }

    # check and see if there were any errors in executing the command
    my $err = $res->getFirstError();
    if ($err) {
        $jnx->disconnect();
        print "ERROR: for $hostname: " . $err->{message} . "\n";
    	return 0;
    }
    return 1;
}


sub outconfig( $$$$ ) {
    my $leader = shift;
    my $hostname = shift;
    my $config = shift;
    my $text_mode = shift;
    my $trailer = "xmlconfig";
    my $filename = $leader . "/" . $hostname . "." . $trailer;

    print "# storing configuration for $hostname as $filename\n";

    my $config_node;
    my $top_tag = "configuration";
    $top_tag .= "-text" if $text_mode;
    if ($config->getTagName() eq $top_tag) {
	$config_node = $config;
    } else {
        print "# unknown response component ", $config->getTagName(), "\n";
    }

    if( $config_node && $config_node ne "" ) {
        if( open OUTPUTFILE, ">$filename" )    {
	    if (!$text_mode) {
                print OUTPUTFILE "<?xml version=\"1.0\"?>\n";
                print OUTPUTFILE $config_node->toString(), "\n";
	    } else {
                my $buf = $config_node->getFirstChild()->toString();
                $buf =~ s/($char_class)/$escapes{$1}/ge;
                print OUTPUTFILE "$buf\n";
            }
            close OUTPUTFILE;
        }
        else {
            print "ERROR: could not open output file $filename\n";
        }
    }
    else {
        print "ERROR: empty configuration data for $hostname\n";
    }
}


sub getconfig ( $$$ ) {
        my $hostname = shift;
        my $jnx = shift;
        my $text_mode = shift;

        # send the command
        my %args = ();
        %args = (format => 'text') if $text_mode; 
        my $res = $jnx->get_configuration(%args);
        unless ( ref $res ) {
            $jnx->disconnect();
            print "ERROR: Failed to fetch configuration for $hostname\n";
        }

        # check and see if there were any errors in executing the command
        my $err = $res->getFirstError();
        if ($err) {
            $jnx->disconnect();
            print "ERROR: error for $hostname: " . $err->{message} . "\n";
        }

        return $res;
}


