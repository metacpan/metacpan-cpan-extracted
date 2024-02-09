use utf8;
package WebService::KvKAPI::Search;
our $VERSION = '0.106';
# ABSTRACT: WebService::KvKAPI::Search package needs a propper abstract

use v5.26;
use Object::Pad;
use WebService::KvKAPI::Formatters ':all';

class WebService::KvKAPI::Search :does(WebService::KvKAPI::Roles::OpenAPI);

ADJUST {
    $self->is_v2(1);
}

my @valid_params = qw(
    kvkNummer
    rsin
    vestigingsnummer
    naam
    straatnaam
    plaats
    postcode
    huisnummer
    huisletter
    postbusnummer
    type
    InclusiefInactieveRegistraties
    pagina
    resultatenPerPagina
);

my %rename = (
    handelsnaam => 'naam',
    aantal => 'resultatenPerPagina',
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

    # Be backward compatible with the old API way
    foreach (keys %rename) {
        next unless exists $args{$_};
        $self->deprecated_item($rename{$_}, $_, "Search");
        $params{$rename{$_}} = $args{$_};
    }

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
  title: API Zoeken
  description: Documentatie voor API Zoeken.
  version: 2.0.0
servers:
- url: /test/api/v2
  description: only for testing with Swagger widget
- url: https://api.kvk.nl/test/api/v2
  description: Test API (uses Staat der Nederlanden Private Root CA – G1 certificate
    chain)
- url: https://api.kvk.nl/api/v2
  description: Production API (uses Staat der Nederlanden Private Root CA – G1 certificate
    chain)
paths:
  /zoeken:
    get:
      tags:
      - Zoeken
      summary: Voor een bedrijf zoeken naar basisinformatie.
      description: Er wordt max. 1000 resultaten getoond.
      operationId: getResults
      parameters:
      - name: kvkNummer
        in: query
        description: Nederlands Kamer van Koophandel nummer dat bestaat uit 8 cijfers
        schema:
          pattern: "^[0-9]{8}$"
          type: string
        example: 59581883
      - name: rsin
        in: query
        description: Rechtspersonen Samenwerkingsverbanden Informatie Nummer dat bestaat
          uit 9 cijfers
        schema:
          pattern: "^[0-9]{9}$"
          type: string
        example: 823807071
      - name: vestigingsnummer
        in: query
        description: Vestigingsnummer dat bestaat uit 12 cijfers
        schema:
          pattern: "^[0-9]{12}$"
          type: string
        example: "000015063097"
      - name: naam
        in: query
        description: De naam waaronder een vestiging of rechtspersoon handelt
        schema:
          type: string
        example: Kamer van Koophandel
      - name: straatnaam
        in: query
        schema:
          type: string
        example: St.-Jacobsstraat
      - name: plaats
        in: query
        schema:
          type: string
        example: Utrecht
      - name: postcode
        in: query
        description: Mag alleen in combinatie met huisnummer of postbusnummer gezocht worden
        schema:
          pattern: "^[0-9]{4}[a-z,A-Z]{2}$"
          type: string
        example: 3511BT
      - name: huisnummer
        in: query
        description: Mag alleen in combinatie met postcode gezocht worden
        schema:
          pattern: "^[0-9]{1,5}$"
          type: integer
        example: 300
      - name: huisletter
        in: query
        description: Optioneel. Alleen in combinatie met huisnummer
        schema:
          pattern: "^[a-z,A-Z]{1}$"
          type: string
        example: D
      - name: postbusnummer
        in: query
        description: Mag alleen in combinatie met postcode gezocht worden
        schema:
          pattern: "^[0-9]{1,5}$"
          type: integer
        example: 9292
      - name: type
        in: query
        description: "Filter op type: hoofdvestiging, nevenvestiging en/of rechtspersoon"
        schema:
          type: array
          items:
            type: string
            enum:
            - hoofdvestiging
            - nevenvestiging
            - rechtspersoon
        example: hoofdvestiging
      - name: inclusiefInactieveRegistraties
        in: query
        description: Inclusief inactieve registraties
        schema:
          type: boolean
        example: true
      - name: pagina
        in: query
        description: "Paginanummer, minimaal 1 en maximaal 1000"
        schema:
          maximum: 1000
          type: integer
          default: 1
      - name: resultatenPerPagina
        in: query
        description: "Kies het aantal resultaten per pagina, minimaal 1 en maximaal\
          \ 100"
        schema:
          maximum: 100
          minimum: 1
          type: integer
          default: 10
      responses:
        "200":
          description: OK
          headers:
            api-version:
              $ref: '#/components/headers/api_version'
            warning:
              $ref: '#/components/headers/warning'
          content:
            application/hal+json:
              schema:
                $ref: '#/components/schemas/Resultaat'
        "400":
          $ref: '#/components/responses/BadRequest'
        "401":
          $ref: '#/components/responses/Unauthorized'
        "403":
          $ref: '#/components/responses/Forbidden'
        "404":
          $ref: '#/components/responses/NotFound'
        "406":
          $ref: '#/components/responses/NotAcceptable'
        "500":
          $ref: '#/components/responses/InternalServerError'
      security:
      - ApiKeyAuth: []
components:
  schemas:
    Adres:
      type: object
      description: Binnenlands of buitenlands adres
      oneOf:
      - $ref: '#/components/schemas/BinnenlandsAdres'
      - $ref: '#/components/schemas/BuitenlandsAdres'
    AdresType:
      type: string
      description: Bezoekadres of postadres
      enum:
      - bezoekadres
      - postadres
    BinnenlandsAdres:
      type: object
      properties:
        binnenlandsAdres:
          $ref: '#/components/schemas/BinnenlandsAdresType'
    BinnenlandsAdresType:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/AdresType'
        straatnaam:
          type: string
        huisnummer:
          type: integer
          format: int32
        huisletter:
          type: string
        postbusnummer:
          type: integer
          description: Postbusnummer wordt alleen getoond indien het een postadres
            betreft
          format: int32
        postcode:
          type: string
        plaats:
          type: string
    BuitenlandsAdres:
      type: object
      properties:
        buitenlandsAdres:
          $ref: '#/components/schemas/BuitenlandsAdresType'
    BuitenlandsAdresType:
      type: object
      properties:
        type:
          $ref: '#/components/schemas/AdresType'
        straatHuisnummer:
          type: string
          description: Het straat/huisnummer is een combinatie van de straat en huisnummer
          example: 53 Rue de Tilsitt
        postcodeWoonplaats:
          type: string
          description: De postcode/woonplaats is de combinatie van een eventuele postcode
            en woonplaats
          example: X-13501 Parijs
        land:
          type: string
          description: De naam van het land waar het adres bevindt
          example: Frankrijk
    Resultaat:
      type: object
      properties:
        pagina:
          type: integer
          description: Geeft aan op welke pagina je bent. Start vanaf pagina 1
          format: int32
        resultatenPerPagina:
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
        _links:
          $ref: '#/components/schemas/Link'
    ResultaatItem:
      type: object
      properties:
        kvkNummer:
          type: string
          description: "Nederlands Kamer van Koophandel nummer dat bestaat uit 8 cijfers"
        rsin:
          type: string
          description: Rechtspersonen Samenwerkingsverbanden Informatie Nummer dat bestaat uit 9 cijfers
        vestigingsnummer:
          type: string
          description: "Vestigingsnummer dat bestaat uit 12 cijfers"
        naam:
          type: string
          description: De naam waaronder een vestiging of rechtspersoon handelt
        adres:
          $ref: '#/components/schemas/Adres'
        type:
          type: string
          description: hoofdvestiging/nevenvestiging/rechtspersoon
        actief:
          type: string
          description: Indicatie of inschrijving actief is
        vervallenNaam:
          type: string
          description: Bevat de vervallen naam waaronder een vestiging of rechtspersoon
            heeft gehandeld
        _links:
          $ref: '#/components/schemas/Link'
    Link:
      type: object
      properties:
        href:
          type: string
        title:
          type: string
    Error:
      type: object
      properties:
        fout:
          type: array
          items:
            $ref: '#/components/schemas/Fout'
    Fout:
      type: object
      properties:
        code:
          type: string
          description: Foutcode
        omschrijving:
          type: string
          description: Omschrijving van de foutmelding
  responses:
    BadRequest:
      description: Een opgegeven parameter is niet valide
      content:
        application/hal+json:
          schema:
            $ref: '#/components/schemas/Error'
    Unauthorized:
      description: Geen of onjuiste apikey aangeleverd
      content:
        application/hal+json:
          schema:
            $ref: '#/components/schemas/Error'
    Forbidden:
      description: Niet geautoriseerd voor deze operatie
      content:
        application/hal+json:
          schema:
            $ref: '#/components/schemas/Error'
    NotFound:
      description: Er zijn geen resultaten gevonden aan de hand van de opgegeven parameter(s)
      content:
        application/hal+json:
          schema:
            $ref: '#/components/schemas/Error'
    NotAcceptable:
      description: Opgegeven Accept header wordt niet ondersteund
      content:
        application/hal+json:
          schema:
            $ref: '#/components/schemas/Error'
    InternalServerError:
      description: Er is een interne fout opgetreden
      content:
        application/hal+json:
          schema:
            $ref: '#/components/schemas/Error'
  headers:
    api_version:
      schema:
        type: string
        description: Geeft een specifieke API-versie aan in de context van een specifieke
          aanroep.
        example: 1.0.0
    warning:
      schema:
        type: string
        description: |-
          zie RFC 7234. In het geval een major versie wordt uitgefaseerd,
          gebruiken we warn-code 299 ("Miscellaneous Persistent Warning") en het API
          end-point (inclusief versienummer) als de warn-agent van de warning, gevolgd
          door de warn-text met de human-readable waarschuwing
        example: |
          299 https://api.kvk.nl/api/v2/zoeken "Deze versie van de API is verouderd
          en zal uit dienst worden genomen op 2025-02-01. Raadpleeg voor meer informatie
          hier de documentatie: https://developers.kvk.nl/nl/apis/zoeken".
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      description: |-
        De API-key die je hebt gekregen dient bij elke request via de `apikey`
        request header meegestuurd te worden. Indien deze niet juist wordt meegestuurd,
        of het een ongeldige key betreft, zul je de foutmelding `401 Unauthorized` terugkrijgen.
      name: apikey
      in: header
