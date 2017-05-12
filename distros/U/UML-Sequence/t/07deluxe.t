use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('UML::Sequence::SimpleSeq'); }

my $out_rec     = UML::Sequence::SimpleSeq->grab_outline_text('t/deluxewash.seq');

#my @correct_out = <DATA>;

#unless (is_deeply($out_rec, \@correct_out, "psiche outline read")) {
#    local $" = "";
#    diag("bad outline\n@$out_rec\n");
#}

my $methods     = UML::Sequence::SimpleSeq->grab_methods($out_rec);
my @methods     = sort keys %$methods;

my @correct_methods = (
"AtHome.Wash Car ",
"Driveway.apply soapy water ",
"Driveway.empty bucket ",
"Driveway.rinse ",
"EXTERNAL",
"Garage.checkDoor ",
"Garage.close door ",
"Garage.get sponge ",
"Garage.open door ",
"Garage.replace bucket ",
"Garage.replace sponge ",
"Garage.retrieve bucket",
"Kitchen.fill bucket ",
"Kitchen.pour soap in bucket ",
"Kitchen.prepare bucket ",
);

unless (is_deeply(\@methods, \@correct_methods, "method list")) {
    local $" = "";
    diag("bad method list\n@methods\n");
}
