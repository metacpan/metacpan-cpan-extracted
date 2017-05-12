use strict;
use warnings;
no warnings "redefine";

use Test::More tests => 4;

use Text::Table;

my %res;
local *Text::Table::stringify = sub { return $res{called} = "1"; };
my $table = Text::Table->new;

$table->add(1,1);
# TEST
ok(! delete $res{called}, "add in void context doesn't stringify()");

$table->load([1,1]);
# TEST
ok(! delete $res{called}, "load in void context doesn't stringify()");

if ( $table ) {}
# TEST
ok(! delete $res{called}, "use as a boolean doesn't stringify()");

my $var = "$table";
# TEST
ok(delete $res{called}, "use as a string calls stringify()");