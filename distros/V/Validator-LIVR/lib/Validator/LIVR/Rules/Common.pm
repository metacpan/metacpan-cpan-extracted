package Validator::LIVR::Rules::Common;

use strict;
use warnings;

our $VERSION = '2.1';

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

=head1 NAME

Validator::LIVR::Rules::Common - Common rules of Validator::LIVR: required, not_empty, not_empty_list and any_object

=head1 DESCRIPTION

This module has the code of the common rules, which are documented in
L<Validator::LIVR/Common rules>.

Each sub is the builder of the rule with the same name. The code is a good
example for L<writing your own rules|Validator::LIVR/WRITING RULES IN PERL>.

=cut
