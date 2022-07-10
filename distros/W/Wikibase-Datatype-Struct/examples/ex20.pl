#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Struct::Lexeme qw(struct2obj);

# Lexeme structure.
my $struct_hr = {
        'claims' => {
                'P5185' => [{
                        'mainsnak' => {
                                'datavalue' => {
                                        'type' => 'wikibase-entityid',
                                        'value' => {
                                                'entity-type' => 'item',
                                                'id' => 'Q499327',
                                                'numeric-id' => 499327,
                                        },
                                },
                                'datatype' => 'wikibase-item',
                                'property' => 'P5185',
                                'snaktype' => 'value',
                        },
                        'rank' => 'normal',
                        'references' => [{
                                'snaks' => {
                                        'P214' => [{
                                                'datavalue' => {
                                                        'type' => 'string',
                                                        'value' => '113230702',
                                                },
                                                'datatype' => 'external-id',
                                                'property' => 'P214',
                                                'snaktype' => 'value',
                                        }],
                                        'P248' => [{
                                                'datavalue' => {
                                                        'type' => 'wikibase-entityid',
                                                        'value' => {
                                                                'entity-type' => 'item',
                                                                'id' => 'Q53919',
                                                                'numeric-id' => 53919,
                                                        },
                                                },
                                                'datatype' => 'wikibase-item',
                                                'property' => 'P248',
                                                'snaktype' => 'value',
                                        }],
                                        'P813' => [{
                                                'datavalue' => {
                                                        'type' => 'time',
                                                        'value' => {
                                                                'after' => 0,
                                                                'before' => 0,
                                                                'calendarmodel' => 'http://test.wikidata.org/entity/Q1985727',
                                                                'precision' => 11,
                                                                'time' => '+2013-12-07T00:00:00Z',
                                                                'timezone' => 0,
                                                        },
                                                },
                                                'datatype' => 'time',
                                                'property' => 'P813',
                                                'snaktype' => 'value',
                                        }],
                                },
                                'snaks-order' => [
                                        'P248',
                                        'P214',
                                        'P813',
                                ],
                        }],
                        'type' => 'statement',
                }],
        },
        'forms' => [{
                'claims' => {
                        'P898' => [{
                                'mainsnak' => {
                                        'datavalue' => {
                                                'type' => 'string',
                                                'value' => decode_utf8('pɛs'),
                                        },
                                        'datatype' => 'string',
                                        'property' => 'P898',
                                        'snaktype' => 'value',
                                },
                                'rank' => 'normal',
                                'type' => 'statement',
                        }],
                },
                'grammaticalFeatures' => [
                        'Q110786',
                        'Q131105',
                ],
                'id' => 'L469-F1',
                'representations' => {
                        'cs' => {
                                'language' => 'cs',
                                'value' => 'pes',
                        },
                },
        }],
        'id' => 'L469',
        'language' => 'Q9056',
        'lastrevid' => 1428556087,
        'lemmas' => {
                'cs' => {
                        'language' => 'cs',
                        'value' => 'pes',
                },
        },
        'lexicalCategory' => 'Q1084',
        'modified' => '2022-06-24T12:42:10Z',
        'ns' => 146,
        'pageid' => 54393954,
        'senses' => [{
                'claims' => {
                        'P18' => [{
                                'mainsnak' => {
                                        'datavalue' => {
                                                'type' => 'string',
                                                'value' => 'Canadian Inuit Dog.jpg',
                                        },
                                        'datatype' => 'commonsMedia',
                                        'property' => 'P18',
                                        'snaktype' => 'value',
                                },
                                'rank' => 'normal',
                                'type' => 'statement',
                        }],
                        'P5137' => [{
                                'mainsnak' => {
                                        'datavalue' => {
                                                'type' => 'wikibase-entityid',
                                                'value' => {
                                                        'entity-type' => 'item',
                                                        'id' => 'Q144',
                                                        'numeric-id' => 144,
                                                },
                                        },
                                        'datatype' => 'wikibase-item',
                                        'property' => 'P5137',
                                        'snaktype' => 'value',
                                },
                                'rank' => 'normal',
                                'type' => 'statement',
                        }],
                },
                'glosses' => {
                        'cs' => {
                                'language' => 'cs',
                                'value' => decode_utf8('psovitá šelma chovaná jako domácí zvíře'),
                        },
                        'en' => {
                                'language' => 'en',
                                'value' => 'domesticated mammal related to the wolf',
                        },
                },
                'id' => 'L469-S1',
        }],
        'title' => 'Lexeme:L469',
        'type' => 'lexeme',
 };

# Get object.
my $obj = struct2obj($struct_hr);

# Dump object.
p $obj;

# Output:
# Wikibase::Datatype::Lexeme  {
#     parents: Mo::Object
#     public methods (5):
#         BUILD
#         Error::Pure:
#             err
#         Mo::utils:
#             check_array_object, check_number
#         Wikibase::Datatype::Utils:
#             check_entity
#     private methods (0)
#     internals: {
#         forms              [
#             [0] Wikibase::Datatype::Form
#         ],
#         id                 "L469",
#         language           "Q9056",
#         lastrevid          1428556087,
#         lemmas             [
#             [0] Wikibase::Datatype::Value::Monolingual
#         ],
#         lexical_category   "Q1084",
#         modified           "2022-06-24T12:42:10Z" (dualvar: 2022),
#         ns                 146,
#         page_id            54393954,
#         senses             [
#             [0] Wikibase::Datatype::Sense
#         ],
#         statements         [
#             [0] Wikibase::Datatype::Statement
#         ],
#         title              "Lexeme:L469"
#     }
# }