use strict;
use warnings;
use utf8;
use v5.12;

package PerlFrundisPackage;

sub quote {
    my $text = shift;
    $text = qq{"$text"};
    return $text;
}

1;
