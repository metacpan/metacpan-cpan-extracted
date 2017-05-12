#!/usr/bin/perl

use VOMS::Lite::VOMS;

$VOMS::Lite::VOMS::DEBUG="yes";

my $ref = VOMS::Lite::VOMS::Server ( {
                                       Server => "0.0.0.0", 
                                       Port => "15050", 
                                       CertFile => "/etc/grid-security/hostcert.pem", 
                                       KeyFile => "/etc/grid-security/hostkey.pem", 
          #                             Inetd => 1,                                 # uncomment me to use xinetd superserver instead of own sockets; use with care
                                       mapfile => "/etc/grid-security/voms-mapfile"
                                     } );

foreach ( @{ ${$ref}{Errors} } )   {print "Error    $_\n";}
foreach ( @{ ${$ref}{Warnings} } ) {print "Warnings $_\n";}

__END__

=head1 NAME

  vomsserver.pl

=head1 SYNOPSIS

  *Experimental* server for VOMS using GSI SSL connection and VOMS protocol

  vomsserver.pl

=head1 DESCRIPTION

  Currently undocumented

=head1 SEE ALSO

This module was originally designed for SHEBANGS, a JISC funded project at The University of Manchester.
http://www.mc.manchester.ac.uk/projects/shebangs/
E<0x0a>now http://www.rcs.manchester.ac.uk/projects/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut

