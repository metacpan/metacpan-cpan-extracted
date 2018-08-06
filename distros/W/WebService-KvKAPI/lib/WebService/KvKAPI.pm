package WebService::KvKAPI;
use Moose;

# ABSTRACT: Query the Dutch Chamber of Commerence (KvK) API

our $VERSION = '0.005';
use namespace::autoclean;
use OpenAPI::Client 0.17;
use Carp;
use Try::Tiny;

with 'MooseX::Log::Log4perl';

has api_key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has client => (
    is      => 'ro',
    isa     => 'OpenAPI::Client',
    lazy    => 1,
    builder => '_build_open_api_client',
);

sub search {
    my ($self, %params) = @_;

    my $results = $self->_search(\%params);
    return $results->{data}{items};
}

sub search_max {
    my ($self, $max, %params) = @_;

    my @items;
    my $answer = $self->_search(\%params);
    push(@items, @{ $answer->{data}{items} });

    while ($answer->{data}{nextLink} && @items < $max) {
        $params{startPage} = $answer->{data}{startPage} + 1;
        $answer = $self->_search(\%params);
        push(@items, @{ $answer->{data}{items} });
    }
    return \@items;
}

sub search_all {
    my ($self, %params) = @_;

    my @items;
    my $answer = $self->_search(\%params);
    push(@items, @{ $answer->{data}{items} });

    while ($answer->{data}{nextLink}) {
        $params{startPage} = $answer->{data}{startPage} + 1;
        $answer = $self->_search(\%params);
        push(@items, @{ $answer->{data}{items} });
    }
    return \@items;
}

sub profile {
    my ($self, %params) = @_;

    my $answer = $self->_profile(\%params);

    if ($answer->{data}{totalItems} == 1) {
        return $answer->{data}{items}[0];
    }

    croak("Unable to find company you where looking for!");
}

sub api_call {
    my ($self, $operation, $query) = @_;

    my $tx = try {
        $self->client->call(
            $operation => { %{$query}, user_key => $self->api_key }
        );
    }
    catch {
        die("Error calling KvK API with operation '$operation': '$_'", $/);
    };

    if ($tx->error) {
        croak(
            sprintf(
                "Error calling KvK API with operation '%s': '%s'",
                $operation, $tx->error->{message}
            ),
        );
    }

    return $tx->res->json;
}

sub _search {
    my ($self, $params) = @_;
    return $self->api_call('Companies_GetCompaniesBasicV2', $params);
}

sub _profile {
    my ($self, $params) = @_;
    return $self->api_call('Companies_GetCompaniesExtendedV2', $params);
}

sub _build_open_api_client {
    my $self = shift;

    my $openapi_url = sprintf('data://%s/kvk_gsasearch_webapi__v1.json', __PACKAGE__);
    return OpenAPI::Client->new($openapi_url);
}


__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=head1 NAME

WebService::KvKAPI - Query the Dutch Chamber of Commerence (KvK) API

=head1 VERSION

version 0.005

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut

__DATA__
@@ kvk_gsasearch_webapi__v1.json
{
   "swagger":"2.0",
   "info":{
      "version":"v1",
      "title":"KvK.GsaSearch.WebApi"
   },
   "host":"api.kvk.nl",
   "schemes":[
      "https"
   ],
   "paths":{
      "/api/v2/search/companies":{
         "get":{
            "tags":[
               "Companies"
            ],
            "summary":"Get a list with basic information about companies",
            "operationId":"Companies_GetCompaniesBasicV2",
            "consumes":[

            ],
            "produces":[
               "application/json",
               "text/json",
               "text/html"
            ],
            "parameters":[
               {
                  "name":"kvkNumber",
                  "in":"query",
                  "description":"KvK number, identifying number for a registration in the Netherlands Business Register. Consists of 8 digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"branchNumber",
                  "in":"query",
                  "description":"Branch number (Vestigingsnummer), identifying number of a branch. Consists of 12 digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"rsin",
                  "in":"query",
                  "description":"RSIN is an identification number for legal entities and partnerships. Consist of only digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"street",
                  "in":"query",
                  "description":"Street of an address",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"houseNumber",
                  "in":"query",
                  "description":"House number of an address",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"postalCode",
                  "in":"query",
                  "description":"Postal code or ZIP code, example 1000AA",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"city",
                  "in":"query",
                  "description":"City or Town name",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"tradeName",
                  "in":"query",
                  "description":"The name under which a company or a branch of a company operates;",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"includeFormerTradeNames",
                  "in":"query",
                  "description":"Indication (true/false) to search through expired trade names and expired registered names and/or include these in the results. Default is false",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"includeInactiveRegistrations",
                  "in":"query",
                  "description":"Indication (true/false) to include searching through inactive dossiers/deregistered companies. Default is false.\r\nNote: History of inactive companies is after 1 January 2013",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"mainBranch",
                  "in":"query",
                  "description":"Search includes main branches. Default is true",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"branch",
                  "in":"query",
                  "description":"Search includes branches. Default is true",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"legalPerson",
                  "in":"query",
                  "description":"Search includes legal persons. Default is true",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"startPage",
                  "in":"query",
                  "description":"Number indicating which page to fetch for pagination. Default = 1, showing the first 10 results",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"site",
                  "in":"query",
                  "description":"Defines the search collection for the query",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"context",
                  "in":"query",
                  "description":"User can optionally add a context to identify his result later on",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"q",
                  "in":"query",
                  "description":"Free format text search for in the compiled search description.",
                  "required":false,
                  "type":"string"
               },
			  {
                  "name":"user_key",
                  "in":"query",
                  "description":"User Key authentication parameter.",
                  "required":true,
                  "type":"string"
               }
            ],
            "responses":{
               "200":{
                  "description":"OK",
                  "schema":{
                     "$ref":"#/definitions/ResultData[CompanyBasicV2]"
                  }
               }
            }
         }
      },
      "/api/v2/profile/companies":{
         "get":{
            "tags":[
               "Companies"
            ],
            "summary":"Get extended information about a specific company or establishment",
            "operationId":"Companies_GetCompaniesExtendedV2",
            "consumes":[

            ],
            "produces":[
               "application/json",
               "text/json",
               "text/html"
            ],
            "parameters":[
               {
                  "name":"kvkNumber",
                  "in":"query",
                  "description":"KvK number, identifying number for a registration in the Netherlands Business Register. Consists of 8 digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"branchNumber",
                  "in":"query",
                  "description":"Branche number (Vestigingsnummer), identifying number of a branch. Consists of 12 digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"rsin",
                  "in":"query",
                  "description":"RSIN is an identification number for legal entities and partnerships. Consist of only digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"includeInactiveRegistrations",
                  "in":"query",
                  "description":"Indication (true/false) to include searching through inactive dossiers/deregistered companies. Default is false.\r\nNote: History of inactive companies is after 1 January 2013",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"restrictToMainBranch",
                  "in":"query",
                  "description":"Search is restricted to main branches. Default is false.",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"site",
                  "in":"query",
                  "description":"Defines the search collection for the query",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"context",
                  "in":"query",
                  "description":"User can optionally add a context to identify his result later on",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"q",
                  "in":"query",
                  "description":"Free format text search for in the compiled search description.",
                  "required":false,
                  "type":"string"
                  },
			  {
                  "name":"user_key",
                  "in":"query",
                  "description":"User Key authentication parameter.",
                  "required":true,
                  "type":"string"
               }
            ],
            "responses":{
               "200":{
                  "description":"OK",
                  "schema":{
                     "$ref":"#/definitions/ResultData[CompanyExtendedV2]"
                  }
               }
            }
         }
      },
      "/api/v2/testsearch/companies":{
         "get":{
            "tags":[
               "CompaniesTest"
            ],
            "summary":"Get a list with basic information about companies",
            "operationId":"CompaniesTest_GetCompaniesBasicV2",
            "consumes":[

            ],
            "produces":[
               "application/json",
               "text/json",
               "text/html"
            ],
            "parameters":[
               {
                  "name":"kvkNumber",
                  "in":"query",
                  "description":"KvK number, identifying number for a registration in the Netherlands Business Register. Consists of 8 digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"branchNumber",
                  "in":"query",
                  "description":"Branch number (Vestigingsnummer), identifying number of a branch. Consists of 12 digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"rsin",
                  "in":"query",
                  "description":"RSIN is an identification number for legal entities and partnerships. Consist of only digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"street",
                  "in":"query",
                  "description":"Street of an address",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"houseNumber",
                  "in":"query",
                  "description":"House number of an address",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"postalCode",
                  "in":"query",
                  "description":"Postal code or ZIP code, example 1000AA",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"city",
                  "in":"query",
                  "description":"City or Town name",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"tradeName",
                  "in":"query",
                  "description":"The name under which a company or a branch of a company operates;",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"includeFormerTradeNames",
                  "in":"query",
                  "description":"Indication (true/false) to search through expired trade names and expired registered names and/or include these in the results. Default is false",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"includeInactiveRegistrations",
                  "in":"query",
                  "description":"Indication (true/false) to include searching through inactive dossiers/deregistered companies. Default is false.\r\nNote: History of inactive companies is after 1 January 2013",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"mainBranch",
                  "in":"query",
                  "description":"Search includes main branches. Default is true",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"branch",
                  "in":"query",
                  "description":"Search includes branches. Default is true",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"legalPerson",
                  "in":"query",
                  "description":"Search includes legal persons. Default is true",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"startPage",
                  "in":"query",
                  "description":"Number indicating which page to fetch for pagination. Default = 1, showing the first 10 results",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"site",
                  "in":"query",
                  "description":"Defines the search collection for the query",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"context",
                  "in":"query",
                  "description":"User can optionally add a context to identify his result later on",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"q",
                  "in":"query",
                  "description":"Free format text search for in the compiled search description.",
                  "required":false,
                  "type":"string"
                  }
            ],
            "responses":{
               "200":{
                  "description":"OK",
                  "schema":{
                     "$ref":"#/definitions/ResultData[CompanyBasicV2]"
                  }
               }
            }
         }
      },
      "/api/v2/testprofile/companies":{
         "get":{
            "tags":[
               "CompaniesTest"
            ],
            "summary":"Get extended information about a specific company or establishment",
            "operationId":"CompaniesTest_GetCompaniesExtendedV2",
            "consumes":[

            ],
            "produces":[
               "application/json",
               "text/json",
               "text/html"
            ],
            "parameters":[
               {
                  "name":"kvkNumber",
                  "in":"query",
                  "description":"KvK number, identifying number for a registration in the Netherlands Business Register. Consists of 8 digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"branchNumber",
                  "in":"query",
                  "description":"Branche number (Vestigingsnummer), identifying number of a branch. Consists of 12 digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"rsin",
                  "in":"query",
                  "description":"RSIN is an identification number for legal entities and partnerships. Consist of only digits",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"includeInactiveRegistrations",
                  "in":"query",
                  "description":"Indication (true/false) to include searching through inactive dossiers/deregistered companies. Default is false.\r\nNote: History of inactive companies is after 1 January 2013",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"restrictToMainBranch",
                  "in":"query",
                  "description":"Search is restricted to main branches. Default is false.",
                  "required":false,
                  "type":"boolean"
               },
               {
                  "name":"site",
                  "in":"query",
                  "description":"Defines the search collection for the query",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"context",
                  "in":"query",
                  "description":"User can optionally add a context to identify his result later on",
                  "required":false,
                  "type":"string"
               },
               {
                  "name":"q",
                  "in":"query",
                  "description":"Free format text search for in the compiled search description.",
                  "required":false,
                  "type":"string"
                }
            ],
            "responses":{
               "200":{
                  "description":"OK",
                  "schema":{
                     "$ref":"#/definitions/ResultData[CompanyExtendedV2]"
                  }
               }
            }
         }
      },
      "/version":{
         "get":{
            "tags":[
               "Version"
            ],
            "operationId":"Version_GetVersion",
            "consumes":[

            ],
            "produces":[
               "application/json",
               "text/json",
               "text/html"
            ],
            "responses":{
               "200":{
                  "description":"OK",
                  "schema":{
                     "type":"object"
                  }
               }
            }
         }
      }
   },
   "definitions":{
      "ResultData[CompanyBasicV2]":{
         "description":"Standardized Resultdata",
         "type":"object",
         "properties":{
            "itemsPerPage":{
               "format":"int32",
               "description":"Amount of search results per page used for the query",
               "type":"integer"
            },
            "startPage":{
               "format":"int32",
               "description":"The current page of the results",
               "type":"integer"
            },
            "totalItems":{
               "format":"int32",
               "description":"Total amount of results spread over multiple pages",
               "type":"integer"
            },
            "nextLink":{
               "description":"Link to next set of ItemsPerPage result items",
               "type":"string"
            },
            "previousLink":{
               "description":"Link to previous set of ItemsPerPage result items",
               "type":"string"
            },
            "query":{
               "description":"Original query",
               "type":"string"
            },
            "items":{
               "description":"Actual search results",
               "type":"array",
               "items":{
                  "$ref":"#/definitions/CompanyBasicV2"
               }
            }
         }
      },
      "CompanyBasicV2":{
         "type":"object",
         "properties":{
            "kvkNumber":{
               "type":"string"
            },
            "branchNumber":{
               "type":"string"
            },
            "rsin":{
               "type":"string"
            },
            "tradeNames":{
               "$ref":"#/definitions/CompanySearchV2TradeNames"
            },
            "hasEntryInBusinessRegister":{
               "type":"boolean"
            },
            "hasNonMailingIndication":{
               "type":"boolean"
            },
            "isLegalPerson":{
               "type":"boolean"
            },
            "isBranch":{
               "type":"boolean"
            },
            "isMainBranch":{
               "type":"boolean"
            },
            "addresses":{
               "description":"At most 1 address is returned",
               "type":"array",
               "items":{
                  "$ref":"#/definitions/CompanySearchV2Address"
               }
            },
            "websites":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            }
         }
      },
      "CompanySearchV2TradeNames":{
         "type":"object",
         "properties":{
            "businessName":{
               "type":"string"
            },
            "shortBusinessName":{
               "type":"string"
            },
            "currentTradeNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "formerTradeNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "currentStatutoryNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "formerStatutoryNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "currentNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "formerNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            }
         }
      },
      "CompanySearchV2Address":{
         "type":"object",
         "properties":{
            "type":{
               "type":"string"
            },
            "street":{
               "type":"string"
            },
            "houseNumber":{
               "type":"string"
            },
            "houseNumberAddition":{
               "type":"string"
            },
            "postalCode":{
               "type":"string"
            },
            "city":{
               "type":"string"
            },
            "country":{
               "type":"string"
            }
         }
      },
      "CompanySearchCriteriaExtendedV2":{
         "description":"Extended Company Search",
         "type":"object",
         "properties":{
            "kvkNumber":{
               "description":"KvK number, identifying number for a registration in the Netherlands Business Register. Consists of 8 digits",
               "type":"string"
            },
            "branchNumber":{
               "description":"Branche number (Vestigingsnummer), identifying number of a branch. Consists of 12 digits",
               "type":"string"
            },
            "rsin":{
               "description":"RSIN is an identification number for legal entities and partnerships. Consist of only digits",
               "type":"string"
            },
            "includeInactiveRegistrations":{
               "description":"Indication (true/false) to include searching through inactive dossiers/deregistered companies. Default is false.\r\nNote: History of inactive companies is after 1 January 2013",
               "type":"boolean"
            },
            "restrictToMainBranch":{
               "description":"Search is restricted to main branches. Default is false.",
               "type":"boolean"
            },
            "isValid":{
               "description":"",
               "type":"boolean",
               "readOnly":true
            },
            "site":{
               "description":"Defines the search collection for the query",
               "type":"string"
            },
            "context":{
               "description":"User can optionally add a context to identify his result later on",
               "type":"string"
            },
            "q":{
               "description":"Free format text search for in the compiled search description.",
               "type":"string"
            }
         }
      },
      "ResultData[CompanyExtendedV2]":{
         "description":"Standardized Resultdata",
         "type":"object",
         "properties":{
            "itemsPerPage":{
               "format":"int32",
               "description":"Amount of search results per page used for the query",
               "type":"integer"
            },
            "startPage":{
               "format":"int32",
               "description":"The current page of the results",
               "type":"integer"
            },
            "totalItems":{
               "format":"int32",
               "description":"Total amount of results spread over multiple pages",
               "type":"integer"
            },
            "nextLink":{
               "description":"Link to next set of ItemsPerPage result items",
               "type":"string"
            },
            "previousLink":{
               "description":"Link to previous set of ItemsPerPage result items",
               "type":"string"
            },
            "query":{
               "description":"Original query",
               "type":"string"
            },
            "items":{
               "description":"Actual search results",
               "type":"array",
               "items":{
                  "$ref":"#/definitions/CompanyExtendedV2"
               }
            }
         }
      },
      "CompanyExtendedV2":{
         "type":"object",
         "properties":{
            "kvkNumber":{
               "type":"string"
            },
            "branchNumber":{
               "type":"string"
            },
            "rsin":{
               "type":"string"
            },
            "tradeNames":{
               "$ref":"#/definitions/CompanyProfileV2TradeNames"
            },
            "legalForm":{
               "type":"string"
            },
            "businessActivities":{
               "type":"array",
               "items":{
                  "$ref":"#/definitions/CompanyProfileV2BusinessActivity"
               }
            },
            "hasEntryInBusinessRegister":{
               "type":"boolean"
            },
            "hasCommercialActivities":{
               "type":"boolean"
            },
            "hasNonMailingIndication":{
               "type":"boolean"
            },
            "isLegalPerson":{
               "type":"boolean"
            },
            "isBranch":{
               "type":"boolean"
            },
            "isMainBranch":{
               "type":"boolean"
            },
            "employees":{
               "format":"int32",
               "type":"integer"
            },
            "foundationDate":{
               "type":"string"
            },
            "registrationDate":{
               "type":"string"
            },
            "deregistrationDate":{
               "type":"string"
            },
            "addresses":{
               "type":"array",
               "items":{
                  "$ref":"#/definitions/CompanyProfileV2Address"
               }
            },
            "websites":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            }
         }
      },
      "CompanyProfileV2TradeNames":{
         "type":"object",
         "properties":{
            "businessName":{
               "type":"string"
            },
            "shortBusinessName":{
               "type":"string"
            },
            "currentTradeNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "formerTradeNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "currentStatutoryNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "formerStatutoryNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "currentNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            },
            "formerNames":{
               "type":"array",
               "items":{
                  "type":"string"
               }
            }
         }
      },
      "CompanyProfileV2BusinessActivity":{
         "type":"object",
         "properties":{
            "sbiCode":{
               "type":"string"
            },
            "sbiCodeDescription":{
               "type":"string"
            },
            "isMainSbi":{
               "type":"boolean"
            }
         }
      },
      "CompanyProfileV2Address":{
         "type":"object",
         "properties":{
            "type":{
               "type":"string"
            },
            "bagId":{
               "type":"string"
            },
            "street":{
               "type":"string"
            },
            "houseNumber":{
               "type":"string"
            },
            "houseNumberAddition":{
               "type":"string"
            },
            "postalCode":{
               "type":"string"
            },
            "city":{
               "type":"string"
            },
            "country":{
               "type":"string"
            },
            "gpsLatitude":{
               "format":"double",
               "type":"number"
            },
            "gpsLongitude":{
               "format":"double",
               "type":"number"
            },
            "rijksdriehoekX":{
               "format":"double",
               "type":"number"
            },
            "rijksdriehoekY":{
               "format":"double",
               "type":"number"
            },
            "rijksdriehoekZ":{
               "format":"double",
               "type":"number"
            }
         }
      }
   }
}

__END__

=head1 DESCRIPTION

Query the KvK API via their OpenAPI definition.

=head1 SYNOPSIS

    use WebService::KvKAPI;
    my $api = WebService::KvKAPI->new(
        api_key => 'foobar',
    );

    $api->search();
    $api->search_all();
    $api->search_max();

=head1 ATTRIBUTES

=head2 api_key

The KvK API key. You can request one at L<https://developers.kvk.nl/>.

=head2 client

An L<OpenAPI::Client> object. Build for you.

=head1 METHODS

=head2 api_call

Directly do an API call towards the KvK API. Returns the JSON datastructure as an C<HashRef>.

=head2 profile

Retreive detailed information of one company. Dies when the company
cannot be found. Make sure to call C<search> first in case you don't
want to die.

=head2 search

Search the KVK, only retrieves the first 10 entries.

    my $results = $self->search(kvkNumber => 12345678, ...);
    foreach (@$results) {
        ...;
    }

=head2 search_all

Search the KVK, retreives ALL entries. Potentially a very expensive call
(money wise). Don't lookup the Albert Heijn KvK number, do more specific
searches

    my $results = $self->search_all(kvkNumber => 12345678, ...);
    foreach (@$results) {
        ...;
    }

=head2 search_max

Search the KVK, retreives a maximum of X results up the the nearest 10, eg 15 as a max returns 20 items.

    my $results = $self->search_max(15, kvkNumber => 12345678, ...);
    foreach (@$results) {
        ...;
    }

=head1 SEE ALSO

The KvK also has test endpoints. While they are supported via the direct
C<api_call> method, you can instantiate a model that works only in
spoofmode: L<WebService::KvKAPI::Spoof>
