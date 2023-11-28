#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use JSON;
use WebService::Kramerius::API4::Item;

if (@ARGV < 2) {
        print STDERR "Usage: $0 library_url work_id\n";
        exit 1;
}
my $library_url = $ARGV[0];
my $work_id = $ARGV[1];

my $obj = WebService::Kramerius::API4::Item->new(
        'library_url' => $library_url,
        'output_dispatch' => {
                'application/json' => sub {
                        my $json = shift;
                        return JSON->new->decode($json);
                },
        },
);

# Get item streams JSON structure as Perl hash.
my $item_streams_json = $obj->get_item_streams($work_id);

p $item_streams_json;

# Output for 'http://kramerius.mzk.cz/' and '314994e0-490a-11de-ad37-000d606f5dc6'
# \ {
#     BIBLIO_MODS    {
#         label      "BIBLIO_MODS description of current object",
#         mimeType   "text/xml"
#     },
#     DC             {
#         label      "Dublin Core Record for this object",
#         mimeType   "text/xml"
#     },
#     IMG_FULL       {
#         label      "",
#         mimeType   "image/jpeg"
#     },
#     IMG_FULL_ADM   {
#         label      "Image administrative metadata",
#         mimeType   "text/xml"
#     },
#     IMG_PREVIEW    {
#         label      "",
#         mimeType   "image/jpeg"
#     },
#     IMG_THUMB      {
#         label      "",
#         mimeType   "image/jpeg"
#     },
#     TEXT_OCR       {
#         label      "",
#         mimeType   "text/plain"
#     },
#     TEXT_OCR_ADM   {
#         label      "Image administrative metadata",
#         mimeType   "text/xml"
#     }
# }