use utf8;
package WebService::KvKAPI::BasicProfile;
our $VERSION = '0.106';
# ABSTRACT: Instance of OpenAPI client for Basisprofiel API of the KvK.

use v5.26;
use Object::Pad;
use WebService::KvKAPI::Formatters qw(format_kvk_number);

class WebService::KvKAPI::BasicProfile :does(WebService::KvKAPI::Roles::OpenAPI);

method get_basic_profile {
    my ($kvk, $geo) = @_;
    return $self->_api_call('getBasisprofielByKvkNummer', $kvk, $geo);
}

method get_owner {
    my ($kvk, $geo) = @_;
    return $self->_api_call('getEigenaar', $kvk, $geo);
}

method get_main_location {
    my ($kvk, $geo) = @_;
    return $self->_api_call('getHoofdvestiging', $kvk, $geo);
}

method get_locations {
    my $kvk = shift;
    return $self->_api_call('getVestigingen', $kvk);
}

method _api_call {
    my ($op, $kvk, $geo) = @_;
    $kvk = format_kvk_number($kvk);
    $geo = $geo ? 1 : 0;
    return $self->api_call(
        $op,
        kvkNummer => $kvk,
        $geo ? (geoData => $geo) : (),
    );
}


1;

=pod

=encoding UTF-8

=head1 NAME

WebService::KvKAPI::BasicProfile - Instance of OpenAPI client for Basisprofiel API of the KvK.

=head1 VERSION

version 0.106

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl / xxllnc, see CONTRIBUTORS file for others.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut

__DATA__
@@ kvkapi.yml

openapi: 3.0.1
info:
  title: API Basisprofiel
  description: Documentatie voor API Basisprofiel.
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
- name: Basisprofiel
paths:
  /v1/basisprofielen/{kvkNummer}:
    get:
      tags:
      - Basisprofiel
      summary: Voor een specifiek bedrijf basisinformatie opvragen.
      operationId: getBasisprofielByKvkNummer
      parameters:
      - name: kvkNummer
        in: path
        description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        required: true
        schema:
          pattern: "^[0-9]{8}$"
          type: string
      - name: geoData
        in: query
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
                $ref: '#/components/schemas/Basisprofiel'
      security:
      - ApiKeyAuth: []
  /v1/basisprofielen/{kvkNummer}/eigenaar:
    get:
      tags:
      - Basisprofiel
      summary: Voor een specifiek bedrijf eigenaar informatie opvragen.
      operationId: getEigenaar
      parameters:
      - name: kvkNummer
        in: path
        description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        required: true
        schema:
          pattern: "^[0-9]{8}$"
          type: string
      - name: geoData
        in: query
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
                $ref: '#/components/schemas/Eigenaar'
      security:
      - ApiKeyAuth: []
  /v1/basisprofielen/{kvkNummer}/hoofdvestiging:
    get:
      tags:
      - Basisprofiel
      summary: Voor een specifiek bedrijf hoofdvestigingsinformatie opvragen.
      operationId: getHoofdvestiging
      parameters:
      - name: kvkNummer
        in: path
        description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        required: true
        schema:
          pattern: "^[0-9]{8}$"
          type: string
      - name: geoData
        in: query
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
  /v1/basisprofielen/{kvkNummer}/vestigingen:
    get:
      tags:
      - Basisprofiel
      summary: Voor een specifiek bedrijf een lijst met vestigingen opvragen.
      operationId: getVestigingen
      parameters:
      - name: kvkNummer
        in: path
        description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        required: true
        schema:
          pattern: "^[0-9]{8}$"
          type: string
      responses:
        default:
          description: default response
          content:
            application/hal+json:
              schema:
                $ref: '#/components/schemas/VestigingList'
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
    Basisprofiel:
      type: object
      properties:
        kvkNummer:
          type: string
          description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        indNonMailing:
          type: string
          description: Hiermee geeft de onderneming aan geen ongevraagde reclame per
            post of verkoop aan de deur te willen ontvangen
        naam:
          type: string
          description: Naam onder Maatschappelijke Activiteit
        formeleRegistratiedatum:
          type: string
          description: Registratiedatum onderneming in HR
        materieleRegistratie:
          $ref: '#/components/schemas/MaterieleRegistratie'
        totaalWerkzamePersonen:
          type: integer
          description: Totaal aantal werkzame personen
          format: int32
        statutaireNaam:
          type: string
          description: De naam van de onderneming wanneer er statuten geregistreerd
            zijn.
        handelsnamen:
          type: array
          description: Alle namen waaronder een onderneming of vestiging handelt (op
            volgorde van registreren)
          items:
            $ref: '#/components/schemas/Handelsnaam'
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
        _embedded:
          $ref: '#/components/schemas/EmbeddedContainer'
    Eigenaar:
      type: object
      properties:
        rsin:
          type: string
          description: Rechtspersonen Samenwerkingsverbanden Informatie Nummer
        rechtsvorm:
          type: string
        uitgebreideRechtsvorm:
          type: string
        adressen:
          type: array
          items:
            $ref: '#/components/schemas/Adres'
        links:
          type: array
          items:
            $ref: '#/components/schemas/Link'
    EmbeddedContainer:
      type: object
      properties:
        hoofdvestiging:
          $ref: '#/components/schemas/Vestiging'
        eigenaar:
          $ref: '#/components/schemas/Eigenaar'
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
    Handelsnaam:
      type: object
      properties:
        naam:
          type: string
        volgorde:
          type: integer
          format: int32
      description: Alle namen waaronder een onderneming of vestiging handelt (op volgorde
        van registreren)
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
    VestigingBasis:
      type: object
      properties:
        vestigingsnummer:
          type: string
          description: "Vestigingsnummer: uniek nummer dat bestaat uit 12 cijfers"
        kvkNummer:
          type: string
          description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        eersteHandelsnaam:
          type: string
          description: De naam waaronder een onderneming of vestiging handelt
        indHoofdvestiging:
          type: string
          description: Hoofdvestiging (Ja/Nee)
        indAdresAfgeschermd:
          type: string
          description: Indicatie of het adres is afgeschermd
        indCommercieleVestiging:
          type: string
          description: Commerciele vestiging  (Ja/Nee)
        volledigAdres:
          type: string
        links:
          type: array
          items:
            $ref: '#/components/schemas/Link'
    VestigingList:
      type: object
      properties:
        kvkNummer:
          type: string
          description: "Nederlands Kamer van Koophandel nummer: bestaat uit 8 cijfers"
        aantalCommercieleVestigingen:
          type: integer
          format: int64
        aantalNietCommercieleVestigingen:
          type: integer
          format: int64
        totaalAantalVestigingen:
          type: integer
          format: int64
        vestigingen:
          type: array
          items:
            $ref: '#/components/schemas/VestigingBasis'
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

A class that implements the Basisprofiel OpenAPI definition of the Dutch
Chamber of Commerce

=head1 SYNOPSIS

    use WebService::KvKAPI::BasicProfile;

    my $api = WebService::KvKAPI::BasicProfile->new(
        # see WebService::KvKAPI->new()
    );

    $api->get_basic_profile($coc_number, $include_geo_data);
    $api->get_owner($coc_number, $include_geo_data);
    $api->get_main_location($coc_number, $include_geo_data);
    $api->get_locations($coc_number);

=head1 METHODS

=head2 get_basic_profile

Get the basic information from a company by their KvK-nummer

=head2 get_owner

Get the owner information from a company by their KvK-nummer

=head2 get_main_location

Get the main location information from a company by their KvK-nummer

=head2 get_locations

Get all the locations from a company by their KvK-nummer
