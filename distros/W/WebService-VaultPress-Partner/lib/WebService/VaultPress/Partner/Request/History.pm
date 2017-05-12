package WebService::VaultPress::Partner::Request::History;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

my $abs_int     = subtype as 'Int', where { $_ >= 0 };
my $limited_int = subtype as 'Int', where { $_ >= 1 and $_ <= 500  };

has api => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'https://partner-api.vaultpress.com/gtm/1.0/usage'
);

has limit => (
    is       => 'ro',
    isa      => $limited_int,
    default  => 100,
);

has offset => (
    is       => 'ro',
    isa      => $abs_int,
    default  => 0,
);

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

WebService::VaultPress::Partner::Request::History - The VaultPress Partner API Client History Request Object

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
WebService::VaultPress::Partner::Request::History class.  You should not instantiate
an object of this class yourself when using WebService::VaultPress::Partner,
it is created by the arguments to ->GetHistory and ->GetRedeemedHistory.  
Its primary purpose is to use Moose's type and error systems to throw errors 
when required  parameters are not passed.

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

WebService::VaultPress::Partner->GetHistory( key => value, … )
WebService::VaultPress::Partner->GetRedeemedHistory( key => value, … )

=item Required

This key is not required.

=item Default Value

Unless explicitly set the value for this method is "https://partner-api.vaultpress.com/gtm/1.0/usage"

=item Value Description

This method provides WebService::VaultPress::Partner with the URL which will be used for the API
call.

=back

=item limit

=over 4

=item Set By

WebService::VaultPress::Partner->GetHistory( key => value, … )
WebService::VaultPress::Partner->GetRedeemedHistory( key => value, … )

=item Required

This key is not required.

=item Default Value

Unless explicitly set this value defaults to 100.

=item Value Description

This method provides WebService::VaultPress::Partner with the number of entries to be returned
by the ->GetHistory and ->GetRedeemedHistory API calls.  The number MUST be
within the inclusive range of 1 to 500.

=back

=item offset

=over 4

=item Set By

WebService::VaultPress::Partner->GetHistory( key => value, … )
WebService::VaultPress::Partner->GetRedeemedHistory( key => value, … )

=item Required

This key is not required.

=item Default Value

Unless explicitly set this value defaults to 0.

=item Value Description

This method provides WebService::VaultPress::Partner with the offset to use by the ->GetHistory 
and ->GetRedeemedHistory API calls.  The number must be a positive integer.

The offset is how many records to skip before fetching the number of records
specified by limit.  For example, ( limit => 100, offset => 100 ) will fetch the
101th to the 200th record.  ( limit => 100 ) will fetch the 1st to 100th record.

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
