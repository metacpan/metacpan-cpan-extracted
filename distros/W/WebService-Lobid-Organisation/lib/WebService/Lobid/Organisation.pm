package WebService::Lobid::Organisation;
$WebService::Lobid::Organisation::VERSION = '0.0031';
# ABSTRACT: interface to the lobid-Organisations API

=head1 NAME

WebService::Lobid::Organisation - interface to the lobid-Organisations API

=head1 SYNOPSIS

 my $Library = WebService::Lobid::Organisation->new(isil=> 'DE-380');
 
 printf("This Library is called '%s', its homepage is at '%s' 
         and it can be found at %f/%f",
     $Library->name, $Library->url, $Library->lat, $Library->long);
 
 print $Library->url->scheme; 

 if ($Library->has_wikipedia){
  printf("%s has its own wikipedia entry: %s",
     $Library->name, $Library->wikipedia);
 } 
 
 if ($Library->has_multiple_emails){
  print $Library->email->[0];
  print $Library->email->[0]->user;
 }else{
  print $Library->email;
  print $Library->email->user;
 }

=head1 METHODS

=over 4

=item new(isil=>$isil)

tries to fetch data for the organisation identified by the ISIL C<$isil>. If an entry is found then the attribute C<found> is set to I<true> 

=back

=head1 ATTRIBUTES

currently the following attributes are supported

=over 4

=item * B<found> (true|false)

indicates if an entry is found

=item * B<isil>

the L<ISIL|https://en.wikipedia.org/wiki/International_Standard_Identifier_for_Libraries_and_Related_Organizations> of the organisation. Has the predicate function I<has_isil>.

=item * B<name>

Has the predicate function I<has_name>.

=item * B<url>

The URL of the institituion as an L<URI> object. Has the predicate 
function I<has_url>

=item * B<provides>

The URL of a resource the institituion provides as an L<URI> object. 
Typically the OPAC. Has the predicate function I<has_url>

=item * B<wikipedia>

Wikpedia entry about the institution as an L<URI> object. Has the predicate 
function I<has_wikipedia>

=item * B<countryName>

Has the predicate function I<has_countryName>

=item * B<locality>

The city or town where institution resides. Has the predicate function I<has_locality>

=item * B<postalCode>

Has the predicate function I<has_postalCoda>

=item * B<streetAddress>

Has the predicate function I<has_streedAddress>

=item * B<email>

Has the predicate function I<has_email>. The email address for the instition including as an L<Email::Address> object. A scalar if there ist just one email address, an array reference if there are more than one adresses (in this case C<has_multiple_emails> is set to I<1>
 
=item * B<has_multiple_emails>

set to I<1> if there is more than one address in C<email>

=item * B<long>

The longitude of the place. Has the predicate function I<has_long>.

=item * B<lat>

The latitude of the place. Has the predicate function I<has_>

=back

=head1 DEPENDENCIES

L<HTTP::Tiny>, L<JSON>, L<Log::Any>, L<Moo>, L<Try::Tiny>

=head1 LOGGING

This module uses the L<Log::Any> Framework

=head1 AUTHOR

Peter Mayr <pmayr@cpan.org>

=head1 REPOSITORY

The source code is also on GitHub <https://github.com/hatorikibble/webservice-lobid-organisations>. Pull requests and bug reports welcome!

=head1 LICENCE AND COPYRIGHT

GNU GPL V3

Peter Mayr 2016

=cut

use strict;
use warnings;

use Email::Address;
use HTTP::Tiny;
use JSON;
use Log::Any;
use Moo;
use Try::Tiny;
use URI;

extends 'WebService::Lobid';

has isil => ( is => 'rw', predicate => 1, required => 1 );
has name => ( is => 'rw', predicate => 1 );
has url  => ( is => 'rw', predicate => 1 );
has provides  => ( is => 'rw', predicate => 1 );
has wikipedia           => ( is => 'rw', predicate => 1 );
has countryName         => ( is => 'rw', predicate => 1 );
has locality            => ( is => 'rw', predicate => 1 );
has postalCode          => ( is => 'rw', predicate => 1 );
has streetAddress       => ( is => 'rw', predicate => 1 );
has email               => ( is => 'rw', predicate => 1 );
has has_multiple_emails => ( is => 'rw', default   => 0 );
has long                => ( is => 'rw', predicate => 1 );
has lat                 => ( is => 'rw', predicate => 1 );
has found               => ( is => 'rw', default   => 'false' );

has log => (
    is      => 'ro',
    default => sub { Log::Any->get_logger },
);

sub BUILD {
    my $self = shift;

    my $query_string  = undef;
    my $response      = undef;
    my $json_result   = undef;
    my $result_ref    = undef;
    my $no_of_results = undef;
    my %data          = ();
    my $email         = undef;
    my $uri = sprintf( "%s%s/%s", $self->api_url, "organisation", $self->isil );

    $query_string = sprintf( "%s%s?id=%s&format=full",
        $self->api_url, "organisation", $self->isil );

    $self->log->infof( "URL: %s", $query_string );
    $response = HTTP::Tiny->new->get($query_string);

    if ( $response->{success} ) {
        $json_result = $response->{content};
    }
    else {
        $self->log->errorf( "Problem accessing the API: %s!",
            $response->{status} );
        $result_ref->{success}   = 0;
        $result_ref->{error_msg} = $response->{status};
        return $result_ref;
    }

    $self->log->debugf( "Got JSON Result: %s", $json_result );

    try {
        $result_ref = decode_json($json_result);
    }
    catch {
        $self->log->errorf( "Decoding of response '%s' failed: %s",
            $json_result, $_ );
    };

    if ( $result_ref->[0]->{'http://sindice.com/vocab/search#totalResults'} ) {
        $no_of_results =
          $result_ref->[0]->{'http://sindice.com/vocab/search#totalResults'};
        $self->log->infof( "Got %d results", $no_of_results );
        $self->found("true") if ( $no_of_results == 1 );
    }

    foreach my $g ( @{ $result_ref->[1]->{'@graph'} } ) {
        $data{ $g->{'@id'} } = $g;
    }
    if ( exists( $data{$uri} ) ) {
        $self->log->debugf("Data %s",$data{$uri}); 
        $self->name( $data{$uri}->{name} ) if ( $data{$uri}->{name} );
        $self->url( URI->new($data{$uri}->{url}) )   if ( $data{$uri}->{url} );
	$self->provides( URI->new($data{$uri}->{provides}) )   if ( $data{$uri}->{provides} );
        $self->wikipedia( URI->new($data{$uri}->{wikipedia}) )
          if ( $data{$uri}->{wikipedia} );
        if ( $data{$uri}->{email} ) {
            $email = $data{$uri}->{email};
            if ( ref($email) eq 'ARRAY' ) {    # multiple E-Mail Adresses
                $self->has_multiple_emails(1);
                for ( my $i = 0 ; $i < scalar( @{$email} ) ; $i++ ) {
                    $email->[$i] =~ s/^mailto://;
		    $email->[$i] = Email::Address->new(undef,$email->[$i]);
                }
            }
            else {

                $email =~ s/^mailto://;
                $email = Email::Address->new(undef,$email); 
            }
            $self->email($email);
        }
        if ( $data{$uri}->{location} ) {
            $self->lat( $data{ $data{$uri}->{location} }->{lat} );
            $self->long( $data{ $data{$uri}->{location} }->{long} );
        }
        if ( $data{$uri}->{address} ) {

            $self->countryName( $data{ $data{$uri}->{address} }->{countryName} )
              if ( $data{ $data{$uri}->{address} }->{countryName} );
            $self->locality( $data{ $data{$uri}->{address} }->{locality} )
              if ( $data{ $data{$uri}->{address} }->{locality} );
            $self->postalCode( $data{ $data{$uri}->{address} }->{postalCode} )
              if ( $data{ $data{$uri}->{address} }->{postalCode} );
            $self->streetAddress(
                $data{ $data{$uri}->{address} }->{streetAddress} )
              if ( $data{ $data{$uri}->{address} }->{streetAddress} );

        }

    }

}

1;
