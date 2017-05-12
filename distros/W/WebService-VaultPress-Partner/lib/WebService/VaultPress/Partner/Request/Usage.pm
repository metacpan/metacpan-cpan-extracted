package WebService::VaultPress::Partner::Request::Usage;
use Moose;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

has api => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'https://partner-api.vaultpress.com/gtm/1.0/summary' 
);

1;

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

WebService::VaultPress::Partner::Request::Usage - The VaultPress Partner API Client Usage Request Object

=head1 VERSION

version 0.05

=head1 SYNOPSIS
  
  #!/usr/bin/perl
  use warnings;
  use strict;
  use lib 'lib';
  use WebService::VaultPress::Partner;
  
  
  my $vp = WebService::VaultPress::Partner->new(
      key => 'Your API Key Goes Here',
  );
  
  my $result = eval { $vp->GetUsage };
  
  if ( $@ ) {
      print "->GetUsage had an error: $@";
  } else {
      printf( "%7s => %5d\n", $_, $result->$_ ) for qw/ unused basic premium /;
  }
  
  
  
  my @results = $vp->GetHistory;
  
  if ( $@ ) {
      print "->GetHistory had an error: $@";
  } else {
      for my $res ( @results ) {
      printf( "| %-20s | %-20s | %-30s | %-19s | %-19s | %-7s |\n", $res->fname,
          $res->lname, $res->email, $res->created, $res->redeemed, $res->type );
      }
  }
  
  # Give Alan Shore a 'Golden Ticket' to VaultPress
  
  my $ticket = eval { $vp->CreateGoldenTicket(
      fname => 'Alan',
      lname => 'Shore',
      email => 'alan.shore@gmail.com',
  ); };
  
  if ( $@ ) {
      print "->CreateGoldenTicket had an error: $@";
  } else {
      print "You can sign up for your VaultPress account <a href=\""
          . $ticket->ticket ."\">Here!</a>\n";
  }

=head1 DESCRIPTION

This document outlines the methods available through the
WebService::VaultPress::Partner::Request::Usage class.  You should not instantiate
an object of this class yourself when using WebService::VaultPress::Partner,
it is created by the arguments to ->GetUsage.   Its primary purpose is to use
Moose's type and error systems to throw errors when required
parameters are not passed.

WebService::VaultPress::Partner is a set of Perl modules which provides a simple and 
consistent Client API to the VaultPress Partner API.  The main focus of 
the library is to provide classes and functions that allow you to quickly 
access VaultPress from Perl applications.

The modules consist of the WebService::VaultPress::Partner module itself as well as a 
handful of WebService::VaultPress::Partner::Request modules as well as a response object,
WebService::VaultPress::Partner::Response, that provides consistent error and success 
methods.

=head1 METHODS

=over 4

=item api

=over 4

=item Set By

WebService::VaultPress::Partner->GetUsage( key => value, … )

=item Required

This key is not required.

=item Default Value

Unless explicitly set the value for this method is "https://partner-api.vaultpress.com/gtm/1.0/summary"

=item Value Description

This method provides WebService::VaultPress::Partner with the URL which will be used for the API
call.

=back

=back

=head1 SEE ALSO

WebService::VaultPress::Partner VaultPress::Partner::Response VaultPress::Partner::Request::History
WebService::VaultPress::Partner::Usage

=head1 AUTHOR

SymKat I<E<lt>symkat@symkat.comE<gt>>

=head1 COPYRIGHT AND LICENSE

This is free software licensed under a I<BSD-Style> License.  Please see the
LICENSE file included in this package for more detailed information.

=head1 AVAILABILITY

The latest version of this software is available through GitHub at
https://github.com/mediatemple/webservice/vaultpress-partner/

=cut
