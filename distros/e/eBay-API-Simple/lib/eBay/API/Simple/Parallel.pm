package eBay::API::Simple::Parallel;

use strict;
use warnings;

use base 'LWP::Parallel::UserAgent';
use utf8;

our $DEBUG = 0;

=head1 NAME

eBay::API::Simple::Parallel - Support for parallel requests

=head1 USAGE

  my $pua = eBay::API::Simple::Parallel->new();
 
  my $call1 = eBay::API::Simple::RSS->new( {
    parallel => $pua,
  } );

  $call1->execute(
    'http://worldofgood.ebay.com/Clothes-Shoes-Men/43/list?format=rss',
  );

  my $call2 = eBay::API::Simple::RSS->new( {
    parallel => $pua,
  } );

  $call2->execute(
    'http://worldofgood.ebay.com/Home-Garden/46/list?format=rss'
  );

  $pua->wait();

  if ( $pua->has_error() ) {
    print "ONE OR MORE FAILURES!\n";
  }

  print $call1->request_content() . "\n";
  print $call2->response_content() "\n";
  

=head1 PUBLIC METHODS

=head2 new()

  my $pua = ebay::API::Simple::Parallel->new();

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );

    $self->{has_error} = 0;

    return $self;
}

=head2 wait( $timeout )

  $pua->wait();

This method will wait for all requests to complete with an optional timeout.

An array of object instances will be returned.

=cut

sub wait {
    my $self = shift;
    my $timeout = shift;

    my @objects;
    my $entries = $self->SUPER::wait( $timeout );

    for my $key ( keys %$entries ) {
        push( @objects, $entries->{$key}->request->{_ebay_api_simple_instance} );
        delete( $entries->{$key}->request->{_ebay_api_simple_instance}->{parallel} );
        delete( $entries->{$key}->request->{_ebay_api_simple_instance} );
    }

    return \@objects;
}

=head2 has_error

Returns true if any of the calls contain an error.

=cut

sub has_error {
    my $self = shift;

    return $self->{has_error};
}

sub on_connect {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $entry = shift;

    if( $DEBUG ) {
        print STDERR "Parallel Connect: " . $request->url . "\n";
    }
}

sub on_return {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $entry = shift;

    if( $DEBUG ) {
        print STDERR "Parallel Return: " . $request->url . "\n";
    }

    $request->{_ebay_api_simple_instance}->_process_http_request( $response );
    $request->{_ebay_api_simple_instance}->process();

    if( $request->{_ebay_api_simple_instance}->has_error ) {
        $self->{has_error} = 1;
    }
}

sub on_failure {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $entry = shift;

    if( $DEBUG ) {
        print STDERR "Parallel Failure: " . $request->url . "\n";
    }

    $request->{_ebay_api_simple_instance}->_process_http_request( $response );
    $request->{_ebay_api_simple_instance}->process();

    $self->{has_error} = 1;
}

1;

=head1 AUTHOR

Brian Gontowski <bgontowski@gmail.com>

=cut
