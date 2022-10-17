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
my $item_obj = $api->get_item($id);

# Dump response structure.
p $item_obj;

# Output for Q213698 argument like:
# Wikibase::Datatype::Item  {
#     Parents       Mo::Object
#     public methods (9) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), check_array_object (Mo::utils), check_number (Mo::utils), check_number_of_items (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo::is)
#     internals: {
#         aliases        [],
#         descriptions   [],
#         id             "Q213698",
#         labels         [],
#         lastrevid      535146,
#         modified       "2020-12-11T22:26:06Z",
#         ns             0,
#         page_id        304259,
#         sitelinks      [],
#         statements     [],
#         title          "Q213698"
#     }
# }