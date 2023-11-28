#!/usr/bin/env perl

use strict;
use warnings;

use WebService::Kramerius::API4::Feed;

if (@ARGV < 1) {
        print STDERR "Usage: $0 library_url [offset] [limit]\n";
        exit 1;
}
my $library_url = $ARGV[0];
my $offset = $ARGV[1] || 0;
my $limit = $ARGV[2] || 1;

my $obj = WebService::Kramerius::API4::Feed->new(
        'library_url' => $library_url,
);

my $newest_json = $obj->newest({
        'limit' => $limit,
        'offset' => $offset,
});

print $newest_json."\n";

# Output for 'http://kramerius.mzk.cz/', pretty print.
# {
#   "rss": "https://kramerius.mzk.cz/search/inc/home/newest-rss.jsp",
#   "data": [
#     {
#       "issn": "978-80-244-2204-6",
#       "author": [
#         "Kubáček, Lubomír",
#         "Tesaříková, Eva",
#         "Univerzita Palackého Přírodovědecká fakulta"
#       ],
#       "pid": "uuid:bf0e3480-4bbf-11ee-b8f0-005056827e52",
#       "model": "monograph",
#       "datumstr": "2008",
#       "title": "Weakly nonlinear regression models",
#       "root_pid": "uuid:bf0e3480-4bbf-11ee-b8f0-005056827e52",
#       "root_title": "Weakly nonlinear regression models",
#       "policy": "private"
#     }
#   ]
# }