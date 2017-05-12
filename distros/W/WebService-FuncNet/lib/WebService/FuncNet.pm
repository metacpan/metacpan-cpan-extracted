package WebService::FuncNet;

use warnings;
use strict;

use Data::Dumper;
use LWP::UserAgent;
use Carp;

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Schema;

our $VERSION = '0.2';
our $WSDL_URL = 'http://funcnet.eu/soap/FrontEnd.wsdl';

=head1 NAME

WebService::FuncNet - Wrapper around the FuncNet web services

=head1 SYNOPSIS

FuncNet is an open platform for the prediction and comparison of human protein
function. It is funded funded by the European Union’s EMBRACE Network of Excellence, 
and developed in partnership with the ENFIN project.

For more information, you can visit http://funcnet.eu/

   my $ra_ref_proteins   = [ 'A3EXL0','Q8NFN7', 'O75865' ];
   my $ra_query_proteins = [ 'Q9H8H3','Q5SR05','P22676' ];

   my $r = WebService::FuncNet::Request->new( 
      $ra_ref_proteins, 
      $ra_query_proteins,
      'test@example.com' );

   ##
   ## returns a WebService::FuncNet::Job object
   
   my $j = $r->submit( );
      
   my $status = $j->status();

   if ( $status ) {
      
      ##
      ## returns a WebService::FuncNet::Results object
      
      my $r = $j->results;
      print $r->as_xml;
   }

=head1 FUNCTIONS

=head2 init

Internal function used to fetch the FuncNet frontend WSDL file.

Do not use directly.

=cut

sub init {
   my $class = shift;   
   my $ua    = LWP::UserAgent->new();
   
   my $rh_compiled_clients = { };   
   my $wsdlfile;
   
   my $response = 
      $ua->get( $WSDL_URL );

    if ( $response->is_success ) {
       $wsdlfile = $response->decoded_content;
       
       my $WSDL =
         XML::Compile::WSDL11->new( $wsdlfile );

      unless ( $WSDL ) {
         carp "Could not create WSDL object with fetched data.";
         die;
      }

      my @op_defs = $WSDL->operations();

      foreach my $op ( @op_defs ) {
         my $name = $op->{name};
         my $op = $WSDL->operation( operation => $name );
         $rh_compiled_clients->{ $name } = $op->compileClient();
      }
      
      return $rh_compiled_clients;
    }
    
    else {
        carp "Unable to fetch WSDL. Tried $WSDL_URL and it returned ", 
         $response->status_line;
         die;
    }
}

=head1 AUTHOR

Spiros Denaxas, C<< <s.denaxas at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-funcnet at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-FuncNet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::FuncNet

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-FuncNet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-FuncNet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-FuncNet>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-FuncNet/>

=back

=head1 ACKNOWLEDGEMENTS

A I<big> thank you to Andrew Clegg and Ian Sillitoe.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Spiros Denaxas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 REVISION INFO

  Revision:      $Rev: 64 $
  Last editor:   $Author: andrew_b_clegg $
  Last updated:  $Date: 2009-07-06 16:12:20 +0100 (Mon, 06 Jul 2009) $

The latest source code for this project can be checked out from:

  https://funcnet.svn.sf.net/svnroot/funcnet/trunk

=cut


1; # End of WebService::FuncNet
