use utf8;
package WebService::KvKAPI::LocationProfile;
our $VERSION = '0.101';
# ABSTRACT: Instance of OpenAPI client for locatieprofiel API of the KvK.

use v5.26;
use Object::Pad;
use WebService::KvKAPI::Formatters qw(format_location_number);

class WebService::KvKAPI::LocationProfile does WebService::KvKAPI::Roles::OpenAPI;

method get_location_profile {
    my $id  = format_location_number(shift);
    my $geo = shift;
    return $self->api_call(
        'getVestigingByVestigingsnummer',
        vestigingsnummer => $id,
        $geo ? (geoData => 1) : ()
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::KvKAPI::LocationProfile - Instance of OpenAPI client for locatieprofiel API of the KvK.

=head1 VERSION

version 0.101

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
  title: API Vestigingsprofiel
  description: Documentatie voor API Vestigingsprofiel.
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
tags:
- name: Vestigingsprofiel
paths:
  /v1/vestigingsprofielen/{vestigingsnummer}:
    get:
      tags:
      - Vestigingsprofiel
      summary: Voor een specifieke vestiging informatie opvragen.
      operationId: getVestigingByVestigingsnummer
      parameters:
      - name: vestigingsnummer
        in: path
        description: "Vestigingsnummer: uniek nummer dat bestaat uit 12 cijfers"
        required: true
        schema:
          pattern: "^[0-9]{12}$"
          type: string
      - name: geoData
        in: query
        description: "GeoData: (true/false) geef aan of BAG data opgehaald moet worden"
        required: false
        schema:
          type: boolean
          default: false
      responses:
        default:
          description: default response
          content:
            application/hal+json:
              schema:
                $ref: '#/components/schemas/Vestiging'
      security:
      - ApiKeyAuth: []
components:
  schemas:
    Adres:
      type: object
      properties:
        type:
          type: string
          description: Correspondentieadres en/of bezoekadres
        indAfgeschermd:
          type: string
          description: Indicatie of het adres is afgeschermd
        volledigAdres:
          type: string
        straatnaam:
          type: string
        huisnummer:
          type: integer
          format: int32
        huisnummerToevoeging:
          type: string
        huisletter:
          type: string
        aanduidingBijHuisnummer:
          type: string
        toevoegingAdres:
          type: string
        postcode:
          type: string
        postbusnummer:
          type: integer
          format: int32
        plaats:
          type: string
        straatHuisnummer:
          type: string
        postcodeWoonplaats:
          type: string
        regio:
          type: string
        land:
          type: string
        geoData:
          $ref: '#/components/schemas/GeoData'
    GeoData:
      type: object
      properties:
        addresseerbaarObjectId:
          type: string
          description: Unieke BAG id
        nummerAanduidingId:
          type: string
          description: Unieke BAG nummeraanduiding id
        gpsLatitude:
          type: number
          description: Lengtegraad
          format: double
        gpsLongitude:
          type: number
          description: Breedtegraad
          format: double
        rijksdriehoekX:
          type: number
          description: Rijksdriehoek X-coördinaat
          format: double
        rijksdriehoekY:
          type: number
          description: Rijksdriehoek Y-coördinaat
          format: double
        rijksdriehoekZ:
          type: number
          description: Rijksdriehoek Z-coördinaat
          format: double
      description: Basisregistratie Adressen en Gebouwen gegevens uit het kadaster
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
    MaterieleRegistratie:
      type: object
      properties:
        datumAanvang:
          type: string
          description: Startdatum onderneming
        datumEinde:
          type: string
          description: Einddatum onderneming
    SBIActiviteit:
      type: object
      properties:
        sbiCode:
          type: string
        sbiOmschrijving:
          type: string
        indHoofdactiviteit:
          type: string
      description: Code beschrijving van SBI activiteiten conform SBI 2008 (Standard
        Industrial Classification). Er wordt geen maximering toegepast in de resultaten.
        Zie ook KVK.nl/sbi
    Vestiging:
      type: object
      properties:
        vestigingsnummer:
          type: string
          description: "Vestigingsnummer: uniek nummer dat bestaat uit 12 cijfers"
        kvkNummer:
          type: string
          description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        rsin:
          type: string
          description: Rechtspersonen Samenwerkingsverbanden Informatie Nummer
        indNonMailing:
          type: string
          description: Hiermee geeft de onderneming aan geen ongevraagde reclame per
            post of verkoop aan de deur te willen ontvangen
        formeleRegistratiedatum:
          type: string
          description: Registratiedatum onderneming in HR
        materieleRegistratie:
          $ref: '#/components/schemas/MaterieleRegistratie'
        eersteHandelsnaam:
          type: string
          description: De naam waaronder een onderneming of vestiging handelt
        indHoofdvestiging:
          type: string
          description: Hoofdvestiging (Ja/Nee)
        indCommercieleVestiging:
          type: string
          description: Commerciele vestiging  (Ja/Nee)
        voltijdWerkzamePersonen:
          type: integer
          description: Aantal voltijd werkzame personen
        totaalWerkzamePersonen:
          type: integer
          description: Totaal aantal werkzame personen
        deeltijdWerkzamePersonen:
          type: integer
          description: Aantal deeltijd werkzame personen
        adressen:
          type: array
          items:
            $ref: '#/components/schemas/Adres'
        websites:
          type: array
          items:
            type: string
        sbiActiviteiten:
          type: array
          description: Code beschrijving van SBI activiteiten conform SBI 2008 (Standard
            Industrial Classification). Er wordt geen maximering toegepast in de resultaten.
            Zie ook KVK.nl/sbi
          items:
            $ref: '#/components/schemas/SBIActiviteit'
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

A class that implements the Locatieprofiel OpenAPI definition of the Dutch
Chamber of Commerce

=head1 SYNOPSIS

use WebService::KvKAPI::LocationProfile;

my $api = WebService::KvKAPI::LocationProfile->new(
    # see WebService::KvKAPI->new()
);

$api->get_location_profile($location_number);

=head1 METHODS

=head2 get_location_profile

Get the location information from a location based on the location number.
