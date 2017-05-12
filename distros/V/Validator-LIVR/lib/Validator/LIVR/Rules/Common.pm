package Validator::LIVR::Rules::Common;

use strict;
use warnings;

our $VERSION = '2.0';

sub required {
    return sub {
        defined $_[0] && $_[0] ne '' ? undef : 'REQUIRED';
    }
}

sub not_empty {
    return sub {
        ! defined $_[0] || $_[0] ne '' ? undef : "CANNOT_BE_EMPTY"
    };
}

sub not_empty_list {
    return sub {
        my $list = shift;
        return 'CANNOT_BE_EMPTY' if !defined($list) || $list eq '';
        return 'FORMAT_ERROR' if ref($list) ne 'ARRAY';
        return 'CANNOT_BE_EMPTY' unless scalar @$list;
        return;
    }
}

sub any_object {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value) ne 'HASH';
    }
}

1;
