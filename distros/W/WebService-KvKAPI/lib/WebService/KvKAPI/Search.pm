use utf8;
package WebService::KvKAPI::Search;
our $VERSION = '0.103';
# ABSTRACT: WebService::KvKAPI::Search package needs a propper abstract

use v5.26;
use Object::Pad;
use WebService::KvKAPI::Formatters ':all';

class WebService::KvKAPI::Search does WebService::KvKAPI::Roles::OpenAPI;

my @valid_params = qw(
    kvkNummer
    rsin
    vestigingsnummer
    handelsnaam
    straatnaam
    plaats
    postcode
    huisnummer
    type
    InclusiefInactieveRegistraties
    pagina
    aantal
);

method search {
    my %args = @_;

    if ($args{kvkNummer}) {
        $args{kvkNummer} = format_kvk_number($args{kvkNummer});
    }
    if ($args{rsin}) {
        $args{rsin} = format_rsin($args{rsin});
    }
    if ($args{vestigingsnummer}) {
        $args{vestigingsnummer} = format_location_number($args{vestigingsnummer});
    }

    my %params;
    foreach (@valid_params) {
        next unless exists $args{$_};
        $params{$_} = delete $args{$_};
    }

    return $self->api_call('getResults', %params);
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::KvKAPI::Search - WebService::KvKAPI::Search package needs a propper abstract

=head1 VERSION

version 0.103

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut

__DATA__
@@ kvkapi.yml

openapi: 3.0.1
info:
  title: API Zoeken
  description: Documentatie voor API Zoeken.
  version: "1.3"
servers:
- url: /test/api
  description: only for testing with Swagger widget
- url: https://api.kvk.nl/test/api
  description: Test API (uses Staat der Nederlanden Private Root CA – G1 certificate
    chain)
- url: https://api.kvk.nl/api
  description: Production API (uses Staat der Nederlanden Private Root CA – G1 certificate
    chain)
paths:
  /v1/zoeken:
    get:
      tags:
      - Zoeken
      summary: Voor een bedrijf zoeken naar basisinformatie.
      description: Er wordt max. 1000 resultaten getoond.
      operationId: getResults
      parameters:
      - name: kvkNummer
        in: query
        description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        schema:
          pattern: "^[0-9]{8}$"
          type: string
      - name: rsin
        in: query
        description: Rechtspersonen Samenwerkingsverbanden Informatie Nummer
        schema:
          pattern: "^[0-9]{9}$"
          type: string
      - name: vestigingsnummer
        in: query
        description: "Vestigingsnummer: uniek nummer dat bestaat uit 12 cijfers"
        schema:
          pattern: "^[0-9]{12}$"
          type: string
      - name: handelsnaam
        in: query
        description: De naam waaronder een vestiging of rechtspersoon handelt
        schema:
          type: string
      - name: straatnaam
        in: query
        schema:
          type: string
      - name: plaats
        in: query
        schema:
          type: string
      - name: postcode
        in: query
        description: Mag alleen in combinatie met Huisnummer gezocht worden
        schema:
          type: string
      - name: huisnummer
        in: query
        description: Mag alleen in combinatie met Postcode gezocht worden
        schema:
          type: string
      - name: type
        in: query
        description: "Filter op type: hoofdvestiging, nevenvestiging en/of rechtspersoon"
        schema:
          type: string
      - name: InclusiefInactieveRegistraties
        in: query
        description: "Inclusief inactieve registraties: true, false"
        schema:
          type: boolean
      - name: pagina
        in: query
        description: "Paginanummer, minimaal 1 en maximaal 1000"
        schema:
          type: number
          default: "1"
      - name: aantal
        in: query
        description: "Kies het aantal resultaten per pagina, minimaal 1 en maximaal\
          \ 100"
        schema:
          type: number
          default: "10"
      responses:
        default:
          description: default response
          content:
            application/hal+json:
              schema:
                $ref: '#/components/schemas/Resultaat'
      security:
      - ApiKeyAuth: []
components:
  schemas:
    Link:
      type: object
      properties:
        rel:
          type: string
        href:
          type: string
        hreflang:
          type: string
        media:
          type: string
        title:
          type: string
        type:
          type: string
        deprecation:
          type: string
        profile:
          type: string
        name:
          type: string
    Resultaat:
      type: object
      properties:
        pagina:
          type: integer
          description: Geeft aan op welke pagina je bent. Start vanaf pagina 1
          format: int32
        aantal:
          type: integer
          description: Geeft het aantal zoek resultaten per pagina weer
          format: int32
        totaal:
          type: integer
          description: Totaal aantal zoekresultaten gevonden. De API Zoeken toont
            max. 1000 resultaten.
          format: int32
        vorige:
          type: string
          description: Link naar de vorige pagina indien beschikbaar
        volgende:
          type: string
          description: Link naar de volgende pagina indien beschikbaar
        resultaten:
          type: array
          items:
            $ref: '#/components/schemas/ResultaatItem'
        links:
          type: array
          items:
            $ref: '#/components/schemas/Link'
    ResultaatItem:
      type: object
      properties:
        kvkNummer:
          type: string
          description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        rsin:
          type: string
          description: Rechtspersonen Samenwerkingsverbanden Informatie Nummer
        vestigingsnummer:
          type: string
          description: "Vestigingsnummer: uniek nummer dat bestaat uit 12 cijfers"
        handelsnaam:
          type: string
          description: De naam waaronder een vestiging of rechtspersoon handelt
        straatnaam:
          type: string
        huisnummer:
          type: integer
          format: int32
        huisnummerToevoeging:
          type: string
        postcode:
          type: string
          example: "Postcode: bestaat uit 4 cijfers en 2 letters"
        plaats:
          type: string
        type:
          type: string
          description: hoofdvestiging/nevenvestiging/rechtspersoon
        actief:
          type: string
          description: Indicatie of inschrijving actief is
        vervallenNaam:
          type: string
          description: Bevat de vervallen handelsnaam of statutaire naam waar dit
            zoekresultaat mee gevonden is.
        links:
          type: array
          items:
            $ref: '#/components/schemas/Link'
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      name: apikey
      in: header
__END__

=head1 DESCRIPTION

A class that implements the Zoeken OpenAPI definition of the Dutch Chamber of
Commerce.

=head1 SYNOPSIS

use WebService::KvKAPI::Search;

my $api = WebService::KvKAPI::Search->new(
    # see WebService::KvKAPI->new()
);

$api->search(%args);

=head1 ATTRIBUTES

=head1 METHODS

=head2 search

Search the KvK registry. Searching on zipcode and housenumber can only be done
when both are supplied.

    $api->search(
        kvkNummer        => '12345678',
        rsin             => '123456789',
        vestigingsnummer => '123456789012',
        handelsnaam      => 'Tradename',
        straatnaam       => 'Street',
        plaats           => 'City',

        # Must always be acompanied by the other
        postcode         => '1234AA',
        huisnummer       => '9',

        type => 'rechtspersoon', # hoofdvestiging/nevenvestiging/rechtspersoon',

        # include inactive registrations, default to 0
        InclusiefInactieveRegistraties => 1,

        # pagination options
        pagina => 1,       # defaults to 1
        aantal => 10,      # defaults to 10
    );
