package jBilling::Client::SOAP::JavaDouble;
use strict;
use warnings;
our $VERSION = 0.01;

use Scalar::Util qw(looks_like_number);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( toDouble fromDouble );

sub toDouble {
    my $number = shift;
    if (defined($number) and looks_like_number($number)) {
        return sprintf('%0.10f',$number);
    } else {
        return 0;
    }
}

sub fromDouble {
    my $number = shift;
    if (defined($number) and looks_like_number($number)) {
        return sprintf('%0.2f',$number);
    } else {
        return 0;
    }
}



1;
