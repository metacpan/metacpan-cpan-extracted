# -*- perl -*-

use Config;

my $script;
$script =~ s/\~\~(\w+)\~\~/$Config::$Config{$1}/g;
if (!open(FILE, ">apacheAdmin")  ||  !(print FILE $script)  ||  !close(FILE)) {
    die "Error while writing apacheAdmin file: $!";
}
chmod 0755, "apacheAdmin";
exit 0;


BEGIN { $script = <<'END_OF_SCRIPT' };
~~startperl~~
#
#   Wizard - A Perl package for implementing system administration
#            applications in the style of Windows wizards.
#
#
#   This module is
#
#           Copyright (C) 1999     Jochen Wiedmann
#                                  Am Eisteich 9
#                                  72555 Metzingen
#                                  Germany
#
#                                  Email: joe@ispsoft.de
#                                  Phone: +49 7123 14887
#
#                          and     Amarendran R. Subramanian
#                                  Grundstr. 32
#                                  72810 Gomaringen
#                                  Germany
#
#                                  Email: amar@ispsoft.de
#                                  Phone: +49 7072 920696
#
#   All Rights Reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#

use strict;

use Getopt::Long ();
use Wizard::Examples::Apache::Admin;

############################################################################
#
#   Global variables
#
############################################################################

use vars qw($debug $verbose)


############################################################################
#
#   This is main()
#
############################################################################

{
    my %o;
    Getopt::Long::GetOptions('debug', 'help', 'host=s', 'server=s', 'start',
                             'stop', 'verbose');
    $debug = 1 if $o{'debug'};
    $o{'verbose'} = 1 if $debug || $o{'verbose'};

    if ($o{'start'}) {
        my $cnf = Wizard::Examples::Apache::Admin->new($o{'host'},
                                                       $o{'server'});
        eval {
            my($config, $interfaces) = $cnf->MakeHttpdConf();
            my $path = $cnf->{'server'}->{'apache-server-confpath'};
            if ((defined($config))
                 and (my $fh = IO::File->new($path, "r"))) {
                $fh->input_record_separator(undef);
	        undef $config if $fh->readline() ne $config;
            }
	    if (defined($config)) {
	        print "Creating new configuration in $path:\n$config\n"
		    if $verbose;
		unless ($debug) {
		    my $fh = IO::AtomicFile->open($path, "w")
		        or die "Failed to create config file $path: $!";
		    ((print $fh $config) and close($fh))
		        or die "Failed to write config file $path: $!";
		}
            } else {
		print "Keeping unmodified configuration in $path.\n";
            }
	    while (my($i, $ip) = each %$interfaces) {
		$cnf->IfUp($i, $ip);
            }
	    my $command = "$cnf->{'host'}->{'apache-host-apachectl'} start";
	    print "Starting Apache: $command\n" if $verbose;
            system $command unless $debug;
        };
        if ($@) {
            $cnf->Error("\nAn error occurred while creating the Apache"
                        . " servers configuration:\n\n$@\n");
        }
    } elsif ($o{'stop'}) {
        my $cnf = Wizard::Examples::Apache::Admin->new($o{'host'},
                                                       $o{'server'});
        eval {
	    my $command = "$cnf->{'host'}->{'apache-host-apachectl'} stop";
	    print "Stopping Apache: $command\n" if $verbose;
            system $command unless $debug;
        };
        if ($@) {
            $cnf->Error("\nAn error occurred while creating the Apache"
                        . " servers configuration:\n\n$@\n");
        }
    } else {
        Usage();
    }
}

END_OF_SCRIPT

