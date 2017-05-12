#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Data::Printer;
use WebService::Ares;

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 ic\n";
        exit 1;
}
my $ic = $ARGV[0];

# Object.
my $obj = WebService::Ares->new;

# Get data.
my $data_hr = $obj->get('standard', {'ic' => $ic});

# Print data.
p $data_hr;

# Output:
# Usage: /tmp/8PICXQSYF3 ic

# Output with (44992785) arguments:
# \ {
#     address       {
#         district     "Brno-město",
#         num          196,
#         num2         1,
#         psc          60200,
#         street       "Dominikánské náměstí",
#         town         "Brno",
#         town_part    "Brno-město",
#         town_urban   "Brno-střed"
#     },
#     create_date   "1992-07-01",
#     firm          "Statutární město Brno",
#     ic            44992785
# }