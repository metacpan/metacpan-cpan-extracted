package WebService::VaultPress::Partner;
use WebService::VaultPress::Partner::Response;
use WebService::VaultPress::Partner::Request::GoldenTicket;
use WebService::VaultPress::Partner::Request::History;
use WebService::VaultPress::Partner::Request::Usage;
use Moose;
use Carp;
use JSON;
use LWP;
use Moose::Util::TypeConstraints;

my $abs_int = subtype as 'Int', where { $_ >= 0 };

our $VERSION = '0.05';
$VERSION = eval $VERSION;

my %cache;

has 'key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'timeout' => (
    is      => 'ro',
    isa     => $abs_int,
    default => 30,
);

has 'user_agent' => (
    is  => 'ro',
    isa => 'Str',
    default => 'WebService::VaultPress::Partner/' . $VERSION,
);

has _ua => (
    is      => 'ro',
    init_arg => undef,
    builder => '_build_ua',
);

no Moose;

# CamelCase linking to Perly methods.
sub CreateGoldenTicket { shift->create_golden_ticket(@_) }
sub GetUsage           { shift->get_usage(@_) }
sub GetHistory         { shift->get_history(@_) }
sub GetRedeemedHistory { shift->get_redeemed_history(@_) }

sub create_golden_ticket {
    my ( $self, %request ) = @_;

    my $req = WebService::VaultPress::Partner::Request::GoldenTicket->new( %request );

    my $res = $self->_ua->post( 
        $req->api,
        {
            key   => $self->key,
            email => $req->email,
            fname => $req->fname,
            lname => $req->lname,
        },
    );

    # Check for HTTP transaction error (timeouts, etc)
    $self->_croak_on_http_error( $res );

    my $json = decode_json( $res->content );
    
    # The API tells us if the call failed.
    die $json->{reason} unless $json->{status};

    return WebService::VaultPress::Partner::Response->new(
        api_call        => 'CreateGoldenTicket',
        ticket          => exists $json->{url}    ? $json->{url} : "",
    );
}

sub get_usage {
    my ( $self, %request ) = @_;
    
    my $req = WebService::VaultPress::Partner::Request::Usage->new( %request );
    
    my $res = $self->_ua->post( $req->api, { key => $self->key } );
    
    # Check for HTTP transaction error (timeouts, etc)
    $self->_croak_on_http_error( $res );

    my $json = decode_json( $res->content );

    # If GetUsage has a status, the call failed.
    die $json->{reason} if exists $json->{status};

    return WebService::VaultPress::Partner::Response->new(
        api_call        => 'GetUsage',
        unused          => exists $json->{unused}  ? $json->{unused}  : 0,
        basic           => exists $json->{basic}   ? $json->{basic}   : 0,
        premium         => exists $json->{premium} ? $json->{premium} : 0,

    );
}

sub get_history {
    my ( $self, %request ) = @_;
    
    my $req = WebService::VaultPress::Partner::Request::History->new( %request );
    
    my $res = $self->_ua->post( 
        $req->api,
        {
            key     => $self->key,
            offset  => $req->offset,
            limit   => $req->limit,
        },
    );
    
    # Check for HTTP transaction error (timeouts, etc)
    $self->_croak_on_http_error( $res );

    my $json = decode_json( $res->content );

    # If the call was successful, we should have
    # an array ref.
    die $json->{reason} unless ( ref $json eq 'ARRAY' );

    my @responses;
    for my $elem ( @{$json} ) {
        push @responses, WebService::VaultPress::Partner::Response->new(
            api_call    => 'GetHistory',
            email       => $elem->{email}       ? $elem->{email}        : "",
            lname       => $elem->{lname}       ? $elem->{lname}        : "",
            fname       => $elem->{fname}       ? $elem->{fname}        : "",
            created     => $elem->{created_on}  ? $elem->{created_on}   : "",
            redeemed    => $elem->{redeemed_on} ? $elem->{redeemed_on}  : "",
            type        => $elem->{type}        ? $elem->{type}         : "",
        );
    }
    return @responses;
}

# This isn't in the spec, but it will be very useful in some reports,
# and it's on line of code.
sub get_redeemed_history {
    return grep { $_->redeemed ne '0000-00-00 00:00:00' } shift->GetHistory(@_);
}

sub _build_ua {
    my ( $self ) = @_;
    return LWP::UserAgent->new(
        agent => $self->user_agent, 
        timeout => $self->timeout,
    );
}

sub _croak_on_http_error {
    my ( $self, $res ) = @_;

    croak $res->status_line unless $res->is_success;
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 NAME

WebService::VaultPress::Partner - The VaultPress Partner API Client

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

WebService::VaultPress::Partner is a set of Perl modules that provide a simple and 
consistent Client API to the VaultPress Partner API.  The main focus of 
the library is to provide classes and functions that allow you to quickly 
access VaultPress from Perl applications.

The modules consist of the WebService::VaultPress::Partner module itself as well as a 
handful of WebService::VaultPress::Partner::Request modules as well as a response object,
WebService::VaultPress::Partner::Response, that provides consistent error and success 
methods.

Error handling is done by die'ing when we run into problems.  Use your favorite
exception handling style to grab errors.

=head1 METHODS

=head2 Constructor

  WebService::VaultPress::Partner->new(
      timeout => 30,
      user_agent => "CoolClient/1.0",
      key => "i have a vaultpress key",
  );

The constructor takes the following input:

=over 4

=item key

  Your API key provided by VaultPress.  Required.

=item timeout

  The HTTP Timeout for all API requests in seconds.  Default: 30

=item user_agent

  The HTTP user-agent for the API to use.  Default: "WebService::VaultPress::Partner/<Version>"

=back

The constructor returns a WebService::VaultPress::Partner object.

=head2 CreateGoldenTicket

The CreateGoldenTicket method provides an interface for creating signup
URLs for VaultPress.

  $ticket = eval { $vp->CreateGoldenTicket(
      api => "https://partner-api.vaultpress.com/gtm/1.0/",
      email => "alan.shore@gmail.com",
      fname => "Alan",
      lname => "Shore",
  ); };

=over 4

=item INPUT

=over 4

=item api

The URL to send the request to.  Default: https://partner-api.vaultpress.com/gtm/1.0/

=item email

The email address of the user you are creating the golden ticket for.

=item fname

The first name of the user you are creating the golden ticket for.

=item lname

The lastname of the user you are creating the golden ticket for.

=back

=item OUTPUT

The CreateGoldenTicket method returns a WebService::VaultPress::Partner::Response
object with the following methods:

=over 4

=item api_call

The method called to generate the response.  In this case 'CreateGoldenTicket'.

=item ticket

The URL for the user to redeem their golden ticket is set here.

=back

=back

=head2 GetHistory

The GetHistory method provides a detailed list of Golden Tickets that
have been given out, while letting you know if they have been redeemed
and what kind of a plan the user signed up for as well as other related
information.

=over 4

=item INPUT

=over 4

=item api

The URL to send the request to.  Default: https://partner-api.vaultpress.com/gtm/1.0/usage

=item limit

The number of results to return, between 1 and 500 inclusive.  Default: 100

=item offset

The number of results to offset by.  Default: 0

An offset of 100 with a limit of 100 will return the 101th to 200th result.

=back


=item OUTPUT

This method returns an array of WebService::VaultPress::Partner::Response objects.

The following will be set:

=over 4

=item api_call

This will be set to 'GetHistory'

=item email

The email address of the user in this history item.

=item lname

The last name of the user in this history item.

=item fname

The first name of the user in this history item.

=item created

The time and date that a Golden Ticket was created for this history
item reported in the form of 'YYYY-MM-DD HH-MM-SS'.

=item redeemed

The time and date that a Golden Ticket was redeemed for this history
item, reported in the form of 'YYYY-MM-DD HH:MM:SS'.

When a history item reflects that this Golden Ticket has not been redeemed
this will be set to '0000-00-00 00:00:00'

=item type

The type of account that the user signed up for.  One of the following:
basic, premium.

When a history item reflects that this Golden Ticket has not been redeemed
this will be set to "".

=back

=back

=head2 GetRedeemedHistory

This method operates exactly as GetHistory, except the returned
history items are guaranteed to have been redeemed.  See GetHistory
for documentation on using this method.

=head2 GetUsage

This method provides a general overview of issued and redeemed Golden
Tickets by giving you the amounts issues, redeemed and the types of redeemd
tickets.

=over 4

=item INPUT

=over 4

=item api

The URL to send the request to.  Default: https://partner-api.vaultpress.com/gtm/1.0/summary

=back


=item OUTPUT

=over 4

=item api_call

This will be set to 'GetUsage'.

=item unused

The number of GoldenTickets issued which have not been redeemed.  If no tickets
have been issues or all tickets issues have been redeemed this will be 0.

=item basic

The number of GoldenTickets issued which have been redeemed with the user signing
up for 'basic' type service.  If no tickets have met this condition the value will
be 0.

=item premium

The number of GoldenTickets issued which have been redeemed with the user signing
up for 'premium' type service.  If no tickets have met this condition the value will
be 0.

=back

=back

=head1 AUTHOR

SymKat I<E<lt>symkat@symkat.comE<gt>>

=head1 COPYRIGHT AND LICENSE

This is free software licensed under a I<BSD-Style> License.  Please see the 
LICENSE file included in this package for more detailed information.

=head1 AVAILABILITY

The latest version of this software is available through GitHub at
https://github.com/mediatemple/webservice-vaultpress-partner/

=cut
