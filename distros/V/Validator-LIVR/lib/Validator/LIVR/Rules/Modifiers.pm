package Validator::LIVR::Rules::Modifiers;

use strict;
use warnings;

our $VERSION = '2.0';

sub trim {
    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || ref($value) || $value eq '';

        $$output_ref = $value;
        $$output_ref =~ s/^\s*//;
        $$output_ref =~ s/\s*$//;

        return;
    };
}

sub to_lc {
    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || ref($value) || $value eq '';

        $$output_ref = lc($value);
        return;
    };
}

sub to_uc {
    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || ref($value) || $value eq '';

        $$output_ref = uc($value);
        return;
    };
}

sub remove {
    my $chars = shift;
    my $re = qr/[\Q$chars\E]/;

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || ref($value) || $value eq '';

        $value =~ s/$re//g;

        $$output_ref = $value;
        return;
    };
}

sub leave_only {
    my $chars = shift;
    my $re = qr/[^\Q$chars\E]/;

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || ref($value) || $value eq '';

        $value =~ s/$re//g;

        $$output_ref = $value;
        return;
    };
}

sub default {
    my $default_value = shift;

    return sub {
        my ( $value, undef, $output_ref ) = @_;

        if ( !defined($value) || $value eq '' ) {
            $$output_ref = $default_value;
        }

        return;
    };
}

1;
