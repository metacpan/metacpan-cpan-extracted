#!/usr/bin/env perl

use strict;
use warnings;

use WebService::Kramerius::API4::User;

if (@ARGV < 1) {
        print STDERR "Usage: $0 library_url\n";
        exit 1;
}
my $library_url = $ARGV[0];

my $obj = WebService::Kramerius::API4::User->new(
        'library_url' => $library_url,
);

my $user_json = $obj->user;

print $user_json."\n";

# Output for 'http://kramerius.mzk.cz/', pretty print.
# {
#   "lname": "not_logged",
#   "firstname": "not_logged",
#   "surname": "not_logged",
#   "session": {},
#   "roles": [
#     {
#       "name": "common_users",
#       "id": 1
#     }
#   ],
#   "id": -1,
#   "labels": []
# }