package Test::Kantan::Util;
use strict;
use warnings;
use utf8;
use 5.010_001;
use parent qw(Exporter);
use Data::Dumper ();

our @EXPORT = qw(dump_data truncstr);

sub dump_data {
    my ($value) = @_;

    unless (defined $value) {
        return '(undef)';
    }

    if (ref $value) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Sortkeys = 1;
        $value = Data::Dumper::Dumper($value);
    }
    $value =~ s/\n/\\n/g;
    return $value;
}

sub truncstr {
    my ($message, $cutoff) = @_;
    return $message unless defined $cutoff;

    if (length($message) > $cutoff) {
        return substr($message, 0, $cutoff-3) . '...';
    } else {
        return $message;
    }
}

1;
