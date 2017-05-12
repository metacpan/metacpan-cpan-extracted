#!/usr/bin/perl -w

use Pod::Usage;
use Getopt::Long;
use SOAP::Lite;
use Storable;
use Term::ReadKey;
use strict;

# Global options
our $opt_version;
our $opt_help;
our $opt_man;
our $opt_resource = 'http://localhost/Example/Service';
our $opt_server   = 'http://localhost:8082';
our $opt_authfile = "$ENV{HOME}/.webservice_auth";

# Handle commandline options
Getopt::Long::Configure ('bundling', 'no_ignore_case');
GetOptions(
           'version|V'    => \$opt_version,
           'help|h'       => \$opt_help,
           'man'          => \$opt_man,
           'server|s=s'   => \$opt_server,
           'resource|r=s' => \$opt_resource,
           'authfile|f=s' => \$opt_authfile
           );
our $opt_username = $ARGV[0] || $ENV{USER};

# Handle -V or --version
if ($opt_version) {
    print '$0: $Revision: 1.1 $', "\n";
    exit 0;
}

# Usage
pod2usage(-verbose => 2, -exitstatus => 0) if ($opt_man);
pod2usage(-verbose => 1, -exitstatus => 0) if ($opt_help);

sub main {
    my $soap = SOAP::Lite
        -> uri($opt_resource)
        -> proxy($opt_server,
                 options => {compress_threshold => 10000},
                 );

    my $service = $soap
        -> call(new => 0)
        -> result;
    
    # Prompt user for password
    print "Password: ";
    ReadMode('noecho');
    my $password = ReadLine(0);
    chomp $password;
    ReadMode('normal');
    print "\n";
    
    # Log into server using password
    my $result = $soap->login($service, $opt_username, $password);
    $password = undef; # discard password once we're logged in

    if ($result->fault) {
        print join ', ',
        $result->faultcode,
        $result->faultstring;
        exit -1;
    }

    if (! $result->result) {
        warn "Invalid password\n";
        exit 0;
    }

    my $credentials = $result->result;
    
    # Store auth info to file
    store($credentials, $opt_authfile);
    
    print "Logged in\n";
    return 1;
}

exit main();

__END__

=head1 NAME

login.pl - Logs into a server, storing credentials locally

=head1 SYNOPSIS

login.pl [options] [username]

=head1 DESCRIPTION

This script logs into the server 

=head1 OPTIONS

=over 8

=item B<-V>, B<--version>

Displays the version number of the script and exits.

=item B<-h>, B<--help>

Displays a brief usage message

=item B<--man>

Displays the man page

=item B<-s> I<server_url>, B<--server>=I<server_url>

The URL of the WebService::TestSystem server to connect to.  By default,
it uses 'http://www.osdl.org:8081'.

=item B<-r> I<resource_uri>, B<--resource>=I<resource_uri>

The URI of the service provided by the server.  By default, it uses
'http://www.osdl.org/WebService/TestSystem'.  Users should not typically
need to alter this setting.

=item B<-f> I<authfile>, B<--authfile>=I<authfile>

The path and filename for a file to contain the authorization
credentials provided by the server.  This is a binary file containing a
ticket consisting of the username and a server-provided signature.  By
default, this will be placed in the user's home directory.  Note that if
you override this setting, you will need to also specify the file
location to any other tools that rely on the file for invoking
authenticated operations on the server.

=back

=head1 PREREQUISITES

B<SOAP::Lite>,
B<Pod::Usage>,
B<Getopt::Long>,
B<Storable>,
B<Term::ReadKey>

=head1 AUTHOR

Bryce Harrington E<lt>bryce@osdl.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 Open Source Development Labs
All Rights Reserved.
    This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 REVISION

Revision: $Revision: 1.1 $

=cut
