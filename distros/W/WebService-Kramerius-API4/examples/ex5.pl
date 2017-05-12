#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use WebService::Kramerius::API4::Struct;

if (@ARGV < 2) {
        print STDERR "Usage: $0 library_url work_id\n";
        exit 1;
}
my $library_url = $ARGV[0];
my $work_id = $ARGV[1];

my $obj = WebService::Kramerius::API4::Struct->new(
        'library_url' => $library_url,
);

# Get item Dublin Core stream JSON structure as Perl hash.
my $item_stream_dc_hr = $obj->get_item_streams_one($work_id, 'DC');

p $item_stream_dc_hr;

# Output for 'http://kramerius.mzk.cz/' and '314994e0-490a-11de-ad37-000d606f5dc6'
# \ {
#     dc:identifier        [
#         [0] "uuid:314994e0-490a-11de-ad37-000d606f5dc6",
#         [1] "handle:BOA001/914810"
#     ],
#     dc:rights            "policy:public",
#     dc:title             "[1]",
#     dc:type              "model:page",
#     xmlns:dc             "http://purl.org/dc/elements/1.1/",
#     xmlns:oai_dc         "http://www.openarchives.org/OAI/2.0/oai_dc/",
#     xmlns:xsi            "http://www.w3.org/2001/XMLSchema-instance",
#     xsi:schemaLocation   "http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd"
# }