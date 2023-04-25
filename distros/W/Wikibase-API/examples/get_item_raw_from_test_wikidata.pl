#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::API;

if (@ARGV < 1) {
        print STDERR "Usage: $0 id\n";
        exit 1;
}
my $id = $ARGV[0];

# API object.
my $api = Wikibase::API->new;

# Get item.
my $struct_hr = $api->get_item_raw($id);

# Dump response structure.
p $struct_hr;

# Output for Q213698 argument like:
# {
#     aliases        {},
#     claims         {
#         P623   [
#             [0] {
#                     id                 "Q213698$89A385A8-2BE1-46CA-85FF-E0B53DEBC0F0",
#                     mainsnak           {
#                         datatype    "string",
#                         datavalue   {
#                             type    "string",
#                             value   "101 Great Marques /Andrew Whyte." (dualvar: 101)
#                         },
#                         hash        "db60f4054e0048355b75a07cd84f83398a84f515",
#                         property    "P623",
#                         snaktype    "value"
#                     },
#                     qualifiers         {
#                         P446   [
#                             [0] {
#                                     datatype    "string",
#                                     datavalue   {
#                                         type    "string",
#                                         value   "a[1] c[1]"
#                                     },
#                                     hash        "831cae40e488a0e8f4b06111ab3f1e1f8c42e79a" (dualvar: 831),
#                                     property    "P446",
#                                     snaktype    "value"
#                                 }
#                         ],
#                         P624   [
#                             [0] {
#                                     datatype    "string",
#                                     datavalue   {
#                                         type    "string",
#                                         value   1
#                                     },
#                                     hash        "32eaf6cc04d6387b0925aea349bba4e35d2bc186" (dualvar: 32),
#                                     property    "P624",
#                                     snaktype    "value"
#                                 }
#                         ],
#                         P625   [
#                             [0] {
#                                     datatype    "string",
#                                     datavalue   {
#                                         type    "string",
#                                         value   0
#                                     },
#                                     hash        "7b763330efc9d8269854747714d91ae0d0bc87a0" (dualvar: 7),
#                                     property    "P625",
#                                     snaktype    "value"
#                                 }
#                         ],
#                         P626   [
#                             [0] {
#                                     datatype    "string",
#                                     datavalue   {
#                                         type    "string",
#                                         value   "101 Great Marques /" (dualvar: 101)
#                                     },
#                                     hash        "0d2c3b012d13b9de1477bae831bd6d61a46e8c64",
#                                     property    "P626",
#                                     snaktype    "value"
#                                 }
#                         ],
#                         P628   [
#                             [0] {
#                                     datatype    "string",
#                                     datavalue   {
#                                         type    "string",
#                                         value   "Andrew Whyte."
#                                     },
#                                     hash        "a2c9c46ce7b17b13b197179fb0e5238965066211",
#                                     property    "P628",
#                                     snaktype    "value"
#                                 }
#                         ]
#                     },
#                     qualifiers-order   [
#                         [0] "P624",
#                         [1] "P626",
#                         [2] "P628",
#                         [3] "P446",
#                         [4] "P625"
#                     ],
#                     rank               "normal",
#                     references         [
#                         [0] {
#                                 hash          "98b2538ea26ec4da8e4aab27e74f1d832490a846" (dualvar: 98),
#                                 snaks         {
#                                     P9    [
#                                         [0] {
#                                                 datatype    "wikibase-item",
#                                                 datavalue   {
#                                                     type    "wikibase-entityid",
#                                                     value   {
#                                                         entity-type   "item",
#                                                         id            "Q1886",
#                                                         numeric-id    1886
#                                                     }
#                                                 },
#                                                 hash        "271c3f13dd08a66f38eb2571d2f338e8b4b8074a" (dualvar: 271),
#                                                 property    "P9",
#                                                 snaktype    "value"
#                                             }
#                                     ],
#                                     P21   [
#                                         [0] {
#                                                 datatype    "url",
#                                                 datavalue   {
#                                                     type    "string",
#                                                     value   "http://lccn.loc.gov/87103973/marcxml"
#                                                 },
#                                                 hash        "1e253d1dcb9867353bc71fc7c661cdc777e14885" (dualvar: 1e+253),
#                                                 property    "P21",
#                                                 snaktype    "value"
#                                             }
#                                     ]
#                                 },
#                                 snaks-order   [
#                                     [0] "P9",
#                                     [1] "P21"
#                                 ]
#                             }
#                     ],
#                     type               "statement"
#                 }
#         ]
#     },
#     descriptions   {
#         en   {
#             language   "en",
#             value      87103973
#         },
#         it   {
#             language   "it",
#             value      87103973
#         }
#     },
#     id             "Q213698",
#     labels         {
#         en   {
#             language   "en",
#             value      "101 Great Marques /" (dualvar: 101)
#         },
#         it   {
#             language   "it",
#             value      "101 Great Marques /" (dualvar: 101)
#         }
#     },
#     lastrevid      538778,
#     modified       "2021-03-20T14:35:50Z" (dualvar: 2021),
#     ns             0,
#     pageid         304259,
#     sitelinks      {},
#     title          "Q213698",
#     type           "item"
# }