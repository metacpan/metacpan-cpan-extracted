package WebService::IPRental;

BEGIN {
    $WebService::IPRental::VERSION = '0.02';
}

# ABSTRACT: IP Rental API

use strict;
use warnings;
use SOAP::Lite;

#use SOAP::Lite +trace => 'all';
use Carp 'croak';
use XML::Simple 'XMLin';

$SOAP::Constants::PREFIX_ENC = 'SOAP-ENC';

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : {@_};

    $args->{APIkey}   or croak 'APIkey is required';
    $args->{APIpass}  or croak 'APIpass is required';
    $args->{Username} or croak 'Username is required';
    $args->{Password} or croak 'Password is required';

    $args->{TTL} ||= 780;
    $args->{soap} =
      SOAP::Lite->envprefix('SOAP-ENV')
      ->on_fault( sub { print( Dumper( $_[1]->fault ), "\n" ); } )
      ->on_action( sub { 'urn:IPRentalSoapAPIAction' } )
      ->proxy( 'https://secure.iprental.com/api/', timeout => 5 )
      ->ns( 'urn:IPRentalSoapAPI', 'ns1' )->outputxml(1)->autotype(0);

    bless $args, $class;
}

sub doIpLease {
    my ($self) = @_;

    my @search_request_params;
    foreach my $arg (qw(APIkey APIpass username password )) {
        push @search_request_params,
          SOAP::Data->name($arg)->value( $self->{ ucfirst $arg } )
          ->attr( { 'xsi:type' => "xsd:string" } );
    }
    foreach my $arg ( 'TTL', 'Location' ) {
        push @search_request_params,
          SOAP::Data->name($arg)->value( $self->{$arg} || 0 )
          ->attr( { 'xsi:type' => "xsd:int" } );
    }

    my $request_params =
      SOAP::Data->name('return')->value( [@search_request_params] )
      ->attr( { 'xsi:type' => 'ns1:IPRargs' } );

    my $xml =
      $self->{soap}->call( SOAP::Data->name('ns1:doIpLease'), $request_params );

    my $data = XMLin( $xml, NoAttr => 1 );
    my $response =
      $data->{'SOAP-ENV:Body'}->{'ns1:doIpLeaseResponse'}->{return};

    return $response;
}

sub verboseReponseCode {
    my ( $self, $r ) = @_;

    return "Good, Fresh IP"                     if $r == 202;
    return "Good, Duplicate IP"                 if $r == 203;
    return "Internal Error, Unable to serve IP" if $r == 402;
    return "Unknown User Authentication"        if $r == 403;
    return "Unknown API Authentication"         if $r == 404;
    return "0 IP leases left in your pool"      if $r == 405;
    return "Impermissible network type"         if $r == 406;
    return "Unknown";
}

1;

__END__

=pod

=head1 NAME

WebService::IPRental - IP Rental API

=head1 VERSION

version 0.02

=head1 SYNOPSIS

=head1 DESCRIPTION

    use WebService::IPRental;

    my $ipr = WebService::IPRental->new(
        APIkey   => $APIkey,
        APIpass  => $APIpass,
        Username => $Username,
        Password => $Password,
        TTL      => 780, # optional
        LOcation => 0, # optional
    );
    
    my $resp = $ipr->doIpLease();
    if ($resp->{Response} == '202' or $resp->{Response} == '203') {
        print "Res:  " . $ipr->verboseReponseCode($resp->{Response}) . "\n";
        print "IP:   " . $ipr->verboseReponseCode($resp->{IP}) . "\n";
        print "Port: " . $ipr->verboseReponseCode($resp->{Port}) . "\n";
        print "TTL:  " . $ipr->verboseReponseCode($resp->{TTL}) . "\n";
        
        # $ua->proxy(['http', 'https'], 'http://'. $resp->{IP} . ':' . $resp->{Port});
    } else {
        die 'Caught error: ' . $ipr->verboseReponseCode($resp->{Response});
    }

            /**
             * ========  Response Codes are listed as so ========
             * 
             * ---- Positive ------------------------------------
             *  202 = Good, Fresh IP
             *  203 = Good, Duplicate IP
             * 
             * ---- Negative ------------------------------------
             *  402 = Internal Error, Unable to serve IP
             *  403 = Unknown User Authentication
             *  404 = Unknown API Authentication
             *  405 = 0 IP leases left in your pool
             *  406 = Impermissible network type
             */

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
