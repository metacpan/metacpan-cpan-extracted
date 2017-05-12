#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use JSON;
use WebService::Kramerius::API4;

if (@ARGV < 2) {
        print STDERR "Usage: $0 library_url work_id\n";
        exit 1;
}
my $library_url = $ARGV[0];
my $work_id = $ARGV[1];

my $obj = WebService::Kramerius::API4->new(
        'library_url' => $library_url,
        'output_dispatch' => {
                'application/json' => sub {
                        my $json = shift;
                        return JSON->new->decode($json);
                },
        },
);

# Get item JSON structure as Perl hash.
my $item_json = $obj->get_item($work_id);

p $item_json;

# Output for 'http://kramerius.mzk.cz/' and '314994e0-490a-11de-ad37-000d606f5dc6'
# \ {
#     context      [
#         [0] [
#             [0] {
#                 model   "periodical",
#                 pid     "uuid:5a2dd690-54b9-11de-8bcd-000d606f5dc6"
#             },
#             [1] {
#                 model   "periodicalvolume",
#                 pid     "uuid:303c91b0-490a-11de-921d-000d606f5dc6"
#             },
#             [2] {
#                 model   "periodicalitem",
#                 pid     "uuid:bf1d5df0-49d8-11de-8cb4-000d606f5dc6"
#             },
#             [3] {
#                 model   "page",
#                 pid     "uuid:314994e0-490a-11de-ad37-000d606f5dc6"
#             }
#         ]
#     ],
#     datanode     JSON::PP::Boolean  {
#         Parents       Types::Serialiser::BooleanBase
#         public methods (0)
#         private methods (0)
#         internals: 1
#     },
#     details      {
#         pagenumber   "[1] 
#                         ",
#         type         "TitlePage"
#     },
#     handle       {
#         href   "http://kramerius.mzk.cz/search/handle/uuid:314994e0-490a-11de-ad37-000d606f5dc6"
#     },
#     iiif         "http://kramerius.mzk.cz/search/iiif/uuid:314994e0-490a-11de-ad37-000d606f5dc6",
#     model        "page",
#     pid          "uuid:314994e0-490a-11de-ad37-000d606f5dc6",
#     policy       "public",
#     root_pid     "uuid:5a2dd690-54b9-11de-8bcd-000d606f5dc6",
#     root_title   "Davidova houpačka",
#     title        "[1]",
#     zoom         {
#         type   "zoomify",
#         url    "http://kramerius.mzk.cz/search/zoomify/uuid:314994e0-490a-11de-ad37-000d606f5dc6"
#     }
# }