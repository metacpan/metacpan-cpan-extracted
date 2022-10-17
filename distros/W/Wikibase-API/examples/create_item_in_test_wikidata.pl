#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Wikibase::API;
use Wikibase::Datatype::Item;

# API object.
my $api = Wikibase::API->new;

# Wikibase::Datatype::Item blank object.
my $item_obj = Wikibase::Datatype::Item->new;

# Create item.
my $res = $api->create_item($item_obj);

# Dump response structure.
p $res;

# Output like:
# \ {
#     entity    {
#         aliases        {},
#         claims         {},
#         descriptions   {},
#         id             "Q213698",
#         labels         {},
#         lastrevid      535146,
#         sitelinks      {},
#         type           "item"
#     },
#     success   1
# }