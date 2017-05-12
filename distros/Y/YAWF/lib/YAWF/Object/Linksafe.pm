package YAWF::Object::Linksafe;

use strict;
use warnings;

sub linksafe {
    my $self = shift;
    my $text = shift;
    return unless defined($text);

    $text =~ s/\&auml\;/ae/g;
    $text =~ s/\&ouml\;/oe/g;
    $text =~ s/\&uuml\;/ue/g;
    $text =~ s/\&Auml\;/Ae/g;
    $text =~ s/\&Ouml\;/Oe/g;
    $text =~ s/\&Uuml\;/Ue/g;
    $text =~ s/\&szlig\;/ss/g;
    $text =~ s/ä/ae/g;
    $text =~ s/ö/oe/g;
    $text =~ s/ü/ue/g;
    $text =~ s/Ä/Ae/g;
    $text =~ s/Ö/Oe/g;
    $text =~ s/Ü/Ue/g;
    $text =~ s/ß/ss/g;
    $text =~ s/[^a-z0-9A-Z\!\(\)\[\]\{\}\,\;\:\-\_\+\=\|\@]+/\_/g;
    $text =~ s/_+/_/g;
    $text =~ s/(\W)_/$1/g;
    $text =~ s/_(\W)/$1/g;

    return $text;
}

1;
