#!perl

use strict;
use warnings;
use utf8;
use Test::More;
use Text::Table::Manifold;

my @rows1 = (
    ["こんにちは", "blah", "blah"],
    ["smock", "blah", "blah"],
    ["apple", "blah", "blah"],
);

my @rows2 = (
    ["😄😄", "ac", "ae"],
    ["aa", "😄😄", "ef"],
    ["ab", "ad", "😄😄"],
);

table_is(\@rows1, <<"END_TABLE1", "double-width hiragana");
+----------+----+----+
|          |    |    |
+----------+----+----+
|こんにちは|blah|blah|
|  smock   |blah|blah|
|  apple   |blah|blah|
+----------+----+----+
END_TABLE1

table_is(\@rows2, <<"END_TABLE2", "double-width emoji");
+----+----+----+
|    |    |    |
+----+----+----+
|😄😄| ac | ae |
| aa |😄😄| ef |
| ab | ad |😄😄|
+----+----+----+
END_TABLE2

done_testing;

sub table_is
{
    my ($rowsref, $expected, $label) = @_;
    my $table  = Text::Table::Manifold->new(data => $rowsref);
    my $result = join("\n", @{ $table->render })."\n";
    is($result, $expected, $label);
}
