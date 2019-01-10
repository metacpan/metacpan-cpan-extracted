package WebService::Lobid::Organisation;
$WebService::Lobid::Organisation::VERSION = '0.0041';
# ABSTRACT: interface to the lobid-Organisations API

=head1 NAME

WebService::Lobid::Organisation - interface to the lobid-Organisations API

=head1 SYNOPSIS

 my $Library = WebService::Lobid::Organisation->new(isil=> 'DE-380');
 
 printf("This Library is called '%s', its homepage is at '%s' 
         and it can be found at %f/%f",
     $Library->name, $Library->url, $Library->lat, $Library->long);
 
 if ($Library->has_wikipedia){
  printf("%s has its own wikipedia entry: %s",
     $Library->name, $Library->wikipedia);
 } 
 
 if ($Library->has_multiple_emails){
  print $Library->email->[0];
 }else{
  print $Library->email;

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

Has the predicate function I<has_url>

=item * B<provides>

Service URL, normally the OPAC, Has the predicate function I<has_provides>

=item * B<addressCountry>

Has the predicate function I<has_addressCountry>

=item * B<addressLocality>

The city or town where institution resides. Has the predicate function I<has_addressLocality>

=item * B<postalCode>

Has the predicate function I<has_postalCoda>

=item * B<streetAddress>

Has the predicate function I<has_streedAddress>

=item * B<email>

Has the predicate function I<has_email>. The email address for the instition including a I<mailto:> prefix. A scalar if there ist just one email address, an array reference if there are more than one adresses (in this case C<has_multiple_emails> is set to I<1>
 
=item * B<has_multiple_emails>

set to I<1> if there is more than one address in C<email>

=item * B<lon>

The longitude of the place. Has the predicate function I<has_lon>.

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

use HTTP::Tiny;
use JSON;
use Log::Any;
use Moo;
use Try::Tiny;

extends 'WebService::Lobid';

has isil => ( is => 'rw', predicate => 1, required => 1 );
has name => ( is => 'rw', predicate => 1 );
has url  => ( is => 'rw', predicate => 1 );
has provides  => ( is => 'rw', predicate => 1 );
has addressCountry         => ( is => 'rw', predicate => 1 );
has addressLocality            => ( is => 'rw', predicate => 1 );
has postalCode          => ( is => 'rw', predicate => 1 );
has streetAddress       => ( is => 'rw', predicate => 1 );
has email               => ( is => 'rw', predicate => 1 );
has has_multiple_emails => ( is => 'rw', default   => 0 );
has lon                 => ( is => 'rw', predicate => 1 );
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

    $query_string = sprintf( "%s%s/%s.json",
                             $self->api_url, "organisations", $self->isil );

    $self->log->infof( "URL: %s", $query_string );
    $response = HTTP::Tiny->new->get($query_string);

    if ( $response->{success} ) {
        $json_result = $response->{content};
    }
    else {

        if ( $response->{status} eq '404' ) {
            $self->log->warnf( "ISIL %s not found!", $self->isil );
            $self->found("false");
            return;
        }
        else {
            $self->log->errorf( "Problem accessing the API: %s!",
                                $response->{status} );
            $result_ref->{success}   = 0;
            $result_ref->{error_msg} = $response->{status};

            return $result_ref;
        }
    }

    $self->log->debugf( "Got JSON Result: %s", $json_result );

    try {
        $result_ref = decode_json($json_result);
    }
    catch {
        $self->log->errorf( "Decoding of response '%s' failed: %s",
                            $json_result, $_ );
    };

    if ( $result_ref->{isil} eq $self->isil ) {
        $self->log->infof( "Got result for ISIL %s", $self->isil );
        $self->found("true");
    }

    if ( $result_ref->{email} ) {
        $email = $result_ref->{email};
        if ( ref($email) eq 'ARRAY' ) {    # multiple E-Mail Adresses
            $self->has_multiple_emails(1);
            for ( my $i = 0; $i < scalar( @{$email} ); $i++ ) {
                $email->[$i] =~ s/^mailto://;
            }
        }
        else {

            $email =~ s/^mailto://;

        }
        $self->email($email);
    }

    $self->name( $result_ref->{name} ) if ( $result_ref->{name} );
    $self->url( $result_ref->{url} )   if ( $result_ref->{url} );
    $self->provides( $result_ref->{provides} )   if ( $result_ref->{provides} );

    if (    ( defined( $result_ref->{location} ) )
         && ( ref( $result_ref->{location} ) eq 'ARRAY' ) )
    {
        if ( $result_ref->{location}->[0]->{geo} ) {
            $self->lat( $result_ref->{location}->[0]->{geo}->{lat} );
            $self->lon( $result_ref->{location}->[0]->{geo}->{lon} );
        }
        if ( $result_ref->{location}->[0]->{address} ) {
            $self->addressCountry(
                    $result_ref->{location}->[0]->{address}->{addressCountry} );
            $self->addressLocality(
                   $result_ref->{location}->[0]->{address}->{addressLocality} );
            $self->postalCode(
                        $result_ref->{location}->[0]->{address}->{postalCode} );
            $self->streetAddress(
                     $result_ref->{location}->[0]->{address}->{streetAddress} );

        }
    }

} ## end sub BUILD

1;
